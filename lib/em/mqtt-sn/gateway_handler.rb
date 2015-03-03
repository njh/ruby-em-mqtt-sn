#
# There is only a single instance of GatewayHandler which
# processes UDP packets from all MQTT-SN clients.
#

class EventMachine::MQTTSN::GatewayHandler < EventMachine::Connection
  attr_reader :logger
  attr_reader :connections
  attr_reader :server_address
  attr_reader :server_port

  def initialize(attr)
    @connections = {}
    attr.each_pair do |k,v|
      instance_variable_set("@#{k}", v)
    end

    # Run the cleanup task periodically
    EventMachine.add_periodic_timer(10) { cleanup }
  end

  # UDP packet received by gateway
  def receive_data(data)
    packet = EventMachine::MQTTSN::Packet.parse(data)
    unless packet.nil?
      process_packet(get_peername, packet)
    end
  end

  # Incoming packet received from client
  def process_packet(peername, packet)
    logger.debug("Received MQTT-SN: #{packet.class}")

    if packet.class == EventMachine::MQTTSN::Packet::Connect
      connect(peername, packet)
    else
      connection = @connections[peername]
      unless connection.nil? or !connection.connected?
        case packet
          when EventMachine::MQTTSN::Packet::Register
            register(connection, packet)
          when EventMachine::MQTTSN::Packet::Publish
            publish(connection, packet)
          when EventMachine::MQTTSN::Packet::Subscribe
            subscribe(connection, packet)
          when EventMachine::MQTTSN::Packet::Pingreq
            connection.send_packet MQTT::Packet::Pingreq.new
          when EventMachine::MQTTSN::Packet::Pingresp
            connection.send_packet MQTT::Packet::Pingresp.new
          when EventMachine::MQTTSN::Packet::Disconnect
            disconnect(connection)
          else
            logger.warn("Unable to handle MQTT-SN packet of type: #{packet.class}")
        end
      else
        logger.warn("Received MQTT-SN packet of type: #{packet.class} while not connected")
      end
    end
  end

  # CONNECT received from client - establish connection to server
  def connect(peername, packet)
    # If connection already exists, disconnect first
    if @connections.has_key?(peername)
      logger.warn("Received CONNECT while already connected")
      @connections[peername].disconnect
    end

    # Create a TCP connection to the server
    client_port, client_address = Socket.unpack_sockaddr_in(peername)
    connection = EventMachine::connect(
      server_address, server_port,
      EventMachine::MQTTSN::ServerConnection,
      self, client_address, client_port
    )

    # Store the client ID
    connection.client_id = packet.client_id

    # Send a MQTT connect packet to the server
    connection.send_packet MQTT::Packet::Connect.new(
      :client_id => packet.client_id,
      :keep_alive => packet.keep_alive,
      :clean_session => packet.clean_session
    )

    # Add the connection to the table
    @connections[peername] = connection
  end

  # Handle a MQTT packet coming back from the server
  def relay_from_server(connection, packet)
    logger.debug("Received MQTT: #{packet.inspect}")
    case packet
      when MQTT::Packet::Connack
        # FIXME: re-map the return code
        mqttsn_packet = EventMachine::MQTTSN::Packet::Connack.new(
          :return_code => packet.return_code
        )
        if packet.return_code == 0
          logger.info("#{connection.client_id} is now connected")
        else
          logger.info("#{connection.client_id} failed to connect: #{packet.return_msg}")
        end
      when MQTT::Packet::Suback
        # Check that it is a response to a request we made
        request = connection.remove_from_pending(packet.message_id)
        if request
          logger.debug("#{connection.client_id} now subscribed to '#{request.topic_name}'")
          topic_id_type, topic_id = connection.get_topic_id(request.topic_name)
          mqttsn_packet = EventMachine::MQTTSN::Packet::Suback.new(
            :topic_id_type => topic_id_type,
            :topic_id => topic_id,
            :qos => packet.granted_qos.first,
            :message_id => packet.message_id,
            :return_code => 0x00
          )
        else
          logger.warn("Received Suback from server for something we didn't request: #{packet.inspect}")
        end
      when MQTT::Packet::Publish
        logger.info("#{connection.client_id} recieved publish to '#{packet.topic}'")
        # FIXME: send register if this is a new topic
        topic_id_type, topic_id = connection.get_topic_id(packet.topic)
        mqttsn_packet = EventMachine::MQTTSN::Packet::Publish.new(
          :duplicate => packet.duplicate,
          :qos => packet.qos,
          :retain => packet.retain,
          :topic_id_type => topic_id_type,
          :topic_id => topic_id,
          :message_id => packet.message_id,
          :data => packet.payload
        )
      when MQTT::Packet::Pingreq
        mqttsn_packet = EventMachine::MQTTSN::Packet::Pingreq.new
      when MQTT::Packet::Pingresp
        mqttsn_packet = EventMachine::MQTTSN::Packet::Pingresp.new
      else
        logger.warn("Unable to handle MQTT packet of type: #{packet.class}")
    end

    unless mqttsn_packet.nil?
      send_datagram(mqttsn_packet.to_s, connection.client_address, connection.client_port)
    end
  end

  # REGISTER received from client
  def register(connection, packet)
    regack = EventMachine::MQTTSN::Packet::Regack.new(
      :topic_id_type => :normal,
      :message_id => packet.message_id
    )

    topic_id_type, topic_id = connection.get_topic_id(packet.topic_name)
    unless topic_id.nil?
      regack.return_code = 0x00   # Accepted
      regack.topic_id = topic_id
    else
       regack.return_code = 0x02  # Rejected: invalid topic ID
    end
    send_data(regack.to_s)
  end

  # PUBLISH received from client - pass it on to the server
  def publish(connection, packet)
    if packet.topic_id_type == :short
      topic_name = packet.topic_id
    elsif packet.topic_id_type == :normal
      topic_name = connection.get_topic_name(packet.topic_id)
    end

    if topic_name
      logger.info("#{connection.client_id} publishing to '#{topic_name}'")
      connection.send_packet MQTT::Packet::Publish.new(
        :topic => topic_name,
        :payload => packet.data,
        :retain => packet.retain,
        :qos => packet.qos
      )
    else
      # FIXME: disconnect?
      logger.warn("Invalid topic ID: #{packet.topic_id}")
    end
  end

  # SUBSCRIBE received from client - pass it on to the server
  def subscribe(connection, packet)
    logger.info("#{connection.client_id} subscribing to '#{packet.topic_name}'")
    mqtt_packet = MQTT::Packet::Subscribe.new(
      :message_id => packet.message_id,
      :topics => packet.topic_name
    )
    connection.add_to_pending(packet)
    connection.send_packet(mqtt_packet)
  end

  # Disconnect client from server
  def disconnect(connection)
    if connection.connected?
      logger.info("Disconnected: #{connection.client_id}")
      mqttsn_packet = EventMachine::MQTTSN::Packet::Disconnect.new
      send_datagram(mqttsn_packet.to_s, connection.client_address, connection.client_port)
      connection.disconnect
    end
  end

  # Periodic task to cleanup dead connections
  def cleanup
    connections.each_pair do |key,connection|
      unless connection.connected?
        logger.debug("Destroying connection: #{connection.client_id}")
        @connections.delete(key)
      end
    end
  end
end
