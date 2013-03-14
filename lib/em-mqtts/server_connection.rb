
class EventMachine::MQTTS::ServerConnection < EventMachine::Connection

  attr_reader :logger
  attr_reader :clients

  def initialize(logger)
    @logger = logger
    @clients = {}
  end

  def receive_data(data)
    packet = EventMachine::MQTTS::Packet.parse(data)
    process_packet(packet)
  end

  def send_packet(packet)
    send_data(packet.to_s)
  end

  def process_packet(packet)
    logger.debug(packet.inspect)

    case packet
      when EventMachine::MQTTS::Packet::Connect
        connect(packet)
      when EventMachine::MQTTS::Packet::Register
        register(packet)
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

end
