
class EventMachine::MQTTS::Connection < EventMachine::Connection

  attr_reader :state
  attr_reader :last_sent
  attr_reader :last_received

  def post_init
    @state = :connecting
    @last_sent = 0
    @last_received = 0
    @packet = nil
    @data = ''
    @topic_map = {}
  end

  # Checks whether a connection is full established
  def connected?
    state == :connected
  end

  def receive_data(data)
    @packet = EventMachine::MQTTS::Packet.parse(@data)
    @last_received = Time.now
    process_packet(@packet)
  end

  # The function needs to be sub-classed
  def process_packet(packet)
  end

  def send_packet(packet)
    # FIXME: Throw exception if we aren't connected?
    #unless packet.class == MQTTS::Packet::Connect
    #  raise MQTTS::NotConnectedException if not connected?
    #end

    send_data(packet.to_s)
    @last_sent = Time.now
  end

end
