
class EventMachine::MQTTS::GatewayConnection < EventMachine::Connection

  attr_reader :logger
  attr_reader :clients
  attr_reader :broker_address
  attr_reader :broker_port

  def initialize(attr)
    @clients = {}
    attr.each_pair do |k,v|
      instance_variable_set("@#{k}", v)
    end
  end

  def receive_data(data)
    packet = EventMachine::MQTTS::Packet.parse(data)
    process_packet(packet)
  end

  def send_packet(packet)
    send_data(packet.to_s)
  end

  def process_packet(packet)
    case packet
      when EventMachine::MQTTS::Packet::Connect
        connect(packet)
      when EventMachine::MQTTS::Packet::Register
        register(packet)
      when EventMachine::MQTTS::Packet::Publish
        publish(packet)
      when EventMachine::MQTTS::Packet::Disconnect
        disconnect(packet)
      else
        logger.warn("Unable to handle packet of type: #{packet.class}")
    end
  end

  def state
    peername = get_peername
    if @clients.has_key?(peername)
      @clients[peername]
    else
      port, address = Socket.unpack_sockaddr_in(peername)
      @clients[peername] = EventMachine::MQTTS::ClientState.new(address, port)
    end
  end

  def connect(packet)
    # Mark the client as connected
    state.connected = true
    state.client_id = packet.client_id
    state.keep_alive = packet.keep_alive

    state.broker_connection = EventMachine::MQTT::ClientConnection.connect(
      @broker_address, @broker_port,
      :client_id => packet.client_id,
      :keep_alive => packet.keep_alive
    )

    connack = EventMachine::MQTTS::Packet::Connack.new(
      :return_code => 0x00
    )
    send_packet(connack)
  end

  def register(packet)
    state.topic_map[packet.topic_id] = packet.topic_name

    regack = EventMachine::MQTTS::Packet::Regack.new(
      :topic_id => packet.topic_id,
      :message_id => packet.message_id,
      :return_code => 0x00
    )
    send_packet(regack)
  end

  def publish(packet)
    topic_name = state.topic_map[packet.topic_id]
    logger.info("Publishing to '#{topic_name}': #{packet.data}")

    state.broker_connection.publish(
      topic_name,
      packet.data,
      packet.retain,
      packet.qos
    )
  end

  def disconnect(packet)
    unless state.broker_connection.nil?
      state.broker_connection.disconnect
    end

    disconnect = EventMachine::MQTTS::Packet::Disconnect.new
    send_packet(disconnect)
  end

end
