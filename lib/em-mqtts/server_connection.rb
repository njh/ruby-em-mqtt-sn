
class EventMachine::MQTTS::ServerConnection < EventMachine::MQTTS::Connection

  @@clients = Array.new

  attr_accessor :client_id
  attr_accessor :last_packet
  attr_accessor :keep_alive
  attr_accessor :message_id
  attr_accessor :subscriptions

  attr_reader :timer
  attr_reader :logger

  def initialize(logger)
    @logger = logger
  end

  def post_init
    super
    @state = :wait_connect
    @client_id = nil
    @keep_alive = 0
    @message_id = 0
    @subscriptions = []
    @timer = nil
    logger.debug("TCP connection opened")
  end

  def unbind
    @@clients.delete(self)
    @timer.cancel if @timer
    logger.debug("TCP connection closed")
  end

  def process_packet(packet)
    logger.debug("#{client_id}: #{packet.inspect}")

    if state == :wait_connect and packet.class == MQTTS::Packet::Connect
      connect(packet)
    elsif state == :connected and packet.class == MQTTS::Packet::Pingreq
      ping(packet)
    elsif state == :connected and packet.class == MQTTS::Packet::Subscribe
      subscribe(packet)
    elsif state == :connected and packet.class == MQTTS::Packet::Publish
      publish(packet)
    elsif packet.class == MQTTS::Packet::Disconnect
      logger.info("#{client_id} has disconnected")
      disconnect
    else
      # FIXME: deal with other packet types
      raise MQTTS::ProtocolException.new(
        "Wasn't expecting packet of type #{packet.class} when in state #{state}"
      )
      disconnect
    end
  end

  def connect(packet)
    # FIXME: check the protocol name and version
    # FIXME: check the client id is between 1 and 23 charcters
    self.client_id = packet.client_id

    ## FIXME: disconnect old client with the same ID
    send_packet MQTTS::Packet::Connack.new
    @state = :connected
    @@clients << self
    logger.info("#{client_id} is now connected")

    # Setup a keep-alive timer
    if packet.keep_alive
      @keep_alive = packet.keep_alive
      logger.debug("#{client_id}: Setting keep alive timer to #{@keep_alive} seconds")
      @timer = EventMachine::PeriodicTimer.new(@keep_alive / 2) do
        last_seen = Time.now - @last_received
        if last_seen > @keep_alive * 1.5
         logger.info("Disconnecting '#{client_id}' because it hasn't been seen for #{last_seen} seconds")
         disconnect
        end
      end
    end
  end

  def disconnect
    logger.debug("Closing connection to #{client_id}")
    @state = :disconnected
    close_connection
  end

  def ping(packet)
    send_packet MQTTS::Packet::Pingresp.new
  end

  def subscribe(packet)
    packet.topics.each do |topic,qos|
      self.subscriptions << topic
    end
    logger.info("#{client_id} has subscriptions: #{self.subscriptions}")

    # FIXME: send subscribe acknowledgement
  end

  def publish(packet)
    @@clients.each do |client|
      if client.subscriptions.include?(packet.topic) or client.subscriptions.include?('#')
        client.send_packet(packet)
      end
    end
  end

end
