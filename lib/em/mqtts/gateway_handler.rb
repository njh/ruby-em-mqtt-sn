#
# There is only a single instance of GatewayHandler which
# processes UDP packets from all MQTT-S clients.
#

class EventMachine::MQTTS::GatewayHandler < EventMachine::Connection
  attr_reader :logger
  attr_reader :connections
  attr_reader :broker_address
  attr_reader :broker_port

  def initialize(attr)
    @connections = {}
    attr.each_pair do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end

  # UDP packet received by gateway
  def receive_data(data)
    packet = EventMachine::MQTTS::Packet.parse(data)
    unless packet.nil?
      process_packet(get_peername, packet)
    end
  end

  # Incoming packet received from client
  def process_packet(peername, packet)
    logger.debug("Recieved MQTT-S: #{packet.class}")

    if packet.class == EventMachine::MQTTS::Packet::Connect
      connect(peername, packet)
    else
      connection = @connections[peername]
      unless connection.nil? or !connection.connected?
        case packet
          when EventMachine::MQTTS::Packet::Register
            register(connection, packet)
          when EventMachine::MQTTS::Packet::Publish
            publish(connection, packet)
          when EventMachine::MQTTS::Packet::Subscribe
            subscribe(connection, packet)
          when EventMachine::MQTTS::Packet::Disconnect
            disconnect(connection)
          else
            logger.warn("Unable to handle MQTT-S packet of type: #{packet.class}")
        end
      else
        logger.warn("Recieved MQTT-S packet of type: #{packet.class} while not connected")
      end
    end
  end

  # CONNECT received from client - establish connection to broker
  def connect(peername, packet)
    # If connection already exists, disconnect first
    if @connections.has_key?(peername)
      logger.warn("Recieved CONNECT while already connected")
      @connections[peername].disconnect
    end

    # Create a TCP connection to the broker
    client_port, client_address = Socket.unpack_sockaddr_in(peername)
    connection = EventMachine::connect(
      broker_address, broker_port,
      EventMachine::MQTTS::BrokerConnection,
      self, client_address, client_port
    )

    # Store the client ID
    connection.client_id = packet.client_id

    # Send a MQTT connect packet to the broker
    connection.send_packet MQTT::Packet::Connect.new(
      :client_id => packet.client_id,
      :keep_alive => packet.keep_alive,
      :clean_session => packet.clean_session
    )

    # Add the connection to the table
    @connections[peername] = connection
  end

  # Handle a MQTT packet coming back from the broker
  def relay_from_broker(connection, packet)
    logger.debug("Recieved MQTT: #{packet.inspect}")
    case packet
      when MQTT::Packet::Connack
        # FIXME: re-map the return code
        mqtts_packet = EventMachine::MQTTS::Packet::Connack.new(
          :return_code => packet.return_code
        )
        if packet.return_code == 0
          logger.info("Client #{connection.client_id} is now connected")
        else
          logger.info("Client #{connection.client_id} failed to connect: #{packet.return_msg}")
        end
      when MQTT::Packet::Suback
        logger.info("Now subscribed")
        # FIXME: use the request packet to work out topic name / id
        mqtts_packet = EventMachine::MQTTS::Packet::Suback.new(
          :topic_id => 1,
          :qos => packet.granted_qos.first,
          :message_id => packet.message_id,
          :return_code => 0x00
        )
      when MQTT::Packet::Publish
        logger.info("Recieved publish from broker")
        mqtts_packet = EventMachine::MQTTS::Packet::Publish.new(
          :duplicate => packet.duplicate,
          :qos => packet.qos,
          :retain => packet.retain,
          :topic_id => connection.get_topic_id(packet.topic),
          :message_id => packet.message_id,
          :data => packet.payload
        )
      else
        logger.warn("Unable to handle MQTT packet of type: #{packet.class}")
    end
    
    unless mqtts_packet.nil?
      send_datagram(mqtts_packet.to_s, connection.client_address, connection.client_port)
    end
  end

  # REGISTER received from client
  def register(connection, packet)
    topic_id = connection.get_topic_id(packet.topic_name)

    regack = EventMachine::MQTTS::Packet::Regack.new(
      :topic_id => topic_id,
      :message_id => packet.message_id,
      :return_code => 0x00
    )
    send_data(regack.to_s)
  end

  # PUBLISH received from client - pass it on to the broker
  def publish(connection, packet)
    topic_name = connection.get_topic_name(packet.topic_id)
    if topic_name
      logger.info("Publishing to '#{topic_name}': #{packet.data}")
      connection.send_packet MQTT::Packet::Publish.new(
        :topic => topic_name,
        :payload => packet.data,
        :retain => packet.retain,
        :qos => packet.qos
      )
    else
      logger.warn("Invalid topic ID: #{packet.topic_id}")
    end
  end
  
  # SUBSCRIBE received from client - pass it on to the broker
  def subscribe(connection, packet)
    logger.info("Subscribing to '#{packet.topic_name}'")
    mqtt_packet = MQTT::Packet::Subscribe.new(
      :topics => packet.topic_name,
      :message_id => packet.message_id,
      :duplicate => packet.duplicate,
      :qos => packet.qos
    )
    connection.send_packet(mqtt_packet)
  end

  # Disconnect client from broker
  def disconnect(connection)
    if connection.connected?
      logger.info("Disconnected: #{connection.client_id}")
      mqtts_packet = EventMachine::MQTTS::Packet::Disconnect.new
      send_datagram(mqtts_packet.to_s, connection.client_address, connection.client_port)
      connection.disconnect
    end
  end
end
