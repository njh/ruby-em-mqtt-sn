
class EventMachine::MQTTS::ServerConnection < EventMachine::Connection

  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def post_init
    super
    @state = :wait_connect
    @client_id = nil
    @keep_alive = 0
    @timer = nil
    logger.debug("UDP connection opened")
  end

  def unbind
    logger.debug("UDP connection closed")
  end

  def process_packet(packet)
    logger.info(packet.inspect)

  end

end
