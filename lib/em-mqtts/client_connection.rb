class EventMachine::MQTTS::ClientConnection < EventMachine::MQTTS::Connection
  include EventMachine::Deferrable

  attr_reader :client_id
  attr_reader :keep_alive
  attr_reader :clean_start
  attr_reader :message_id
  attr_reader :ack_timeout
  attr_reader :timer

  # FIXME: change this to optionally take hash of options
  def self.connect(host=MQTTS::DEFAULT_HOST, port=MQTTS::DEFAULT_PORT, *args, &blk)
    EventMachine.connect( host, port, self, *args, &blk )
  end

  def post_init
    super
    @state = :connecting
    @client_id = MQTTS::Client.generate_client_id
    @keep_alive = 10
    @clean_start = true
    @message_id = 0
    @ack_timeout = 5
    @timer = nil
  end

  def connection_completed
    # Protocol name and version
    packet = MQTTS::Packet::Connect.new(
      :clean_start => @clean_start,
      :keep_alive => @keep_alive,
      :client_id => @client_id
    )

    send_packet(packet)

    @state = :connect_sent
  end

  # Disconnect from the MQTT-S gateway.
  # If you don't want to say goodbye to the gateway, set send_msg to false.
  def disconnect(send_msg=true)
    # FIXME: only close if we aren't waiting for any acknowledgements
    if connected?
      send_packet(MQTTS::Packet::Disconnect.new) if send_msg
    end
    @state = :disconnecting
  end

  def receive_callback(&block)
    @receive_callback = block
  end

  def receive_msg(packet)
    # Alternatively, subclass this method
    @receive_callback.call(packet) unless @receive_callback.nil?
  end

  def unbind
    timer.cancel if timer
    unless state == :disconnecting
      raise MQTTS::NotConnectedException.new("Connection to server lost")
    end
    @state = :disconnected
  end

  # Publish a message on a particular topic to the MQTT-S gateway.
  def publish(topic, payload, retain=false, qos=0)
    # Defer publishing until we are connected
    callback do
      send_packet(
        MQTTS::Packet::Publish.new(
          :qos => qos,
          :retain => retain,
          :topic => topic,
          :payload => payload,
          :message_id => @message_id.next
        )
      )
    end
  end

  # Send a subscribe message for one or more topics on the MQTT-S gateway
  def subscribe(*topics)
    # Defer subscribing until we are connected
    callback do
      send_packet(
        MQTTS::Packet::Subscribe.new(
          :topics => topics,
          :message_id => @message_id.next
        )
      )
    end
  end

  # Send a unsubscribe message for one or more topics on the MQTT-S gateway
  def unsubscribe(*topics)
    # Defer unsubscribing until we are connected
    callback do
      send_packet(
        MQTTS::Packet::Unsubscribe.new(
          :topics => topics,
          :message_id => @message_id.next
        )
      )
    end
  end



private

  def process_packet(packet)
    if state == :connect_sent and packet.class == MQTTS::Packet::Connack
      connect_ack(packet)
    elsif state == :connected and packet.class == MQTTS::Packet::Pingresp
      # Pong!
    elsif state == :connected and packet.class == MQTTS::Packet::Publish
      receive_msg(packet)
    elsif state == :connected and packet.class == MQTTS::Packet::Suback
      # Subscribed!
    else
      # FIXME: deal with other packet types
      raise MQTTS::ProtocolException.new(
        "Wasn't expecting packet of type #{packet.class} when in state #{state}"
      )
      disconnect
    end
  end

  def connect_ack(packet)
    if packet.return_code != 0x00
      raise MQTTS::ProtocolException.new(packet.return_msg)
    else
      @state = :connected
    end

    # Send a ping packet every X seconds
    if keep_alive > 0
      @timer = EventMachine::PeriodicTimer.new(keep_alive) do
        send_packet MQTTS::Packet::Pingreq.new
      end
    end

    # We are now connected - can now execute deferred calls
    set_deferred_success
  end

end
