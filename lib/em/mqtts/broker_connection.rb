
class EventMachine::MQTTS::BrokerConnection < EventMachine::MQTT::Connection
  attr_accessor :gateway_handler
  attr_accessor :client_address
  attr_accessor :client_port
  attr_accessor :client_id

  def initialize(gateway_handler, client_address, client_port)
    @client_address = client_address
    @client_port = client_port
    @gateway_handler = gateway_handler
    @topic_id = 1
    @topic_map = {}
  end

  # TCP connection to broker has closed
  def unbind
    @gateway_handler.disconnect(self)
  end

  # Incoming packet from broker has been recieved
  def process_packet(packet)
    if packet.class == MQTT::Packet::Connack and packet.return_code == 0
      @state = :connected
    end
  
    @gateway_handler.relay_from_broker(self, packet)
  end

  # Get the topic ID for a topic name
  def get_topic_id(name)
    # FIXME: improve this
    @topic_map.each_pair do |key,value|
      return key if value == name
    end
    @topic_id += 1
    @topic_map[@topic_id] = name
    return @topic_id
  end
  
  # Get the topic name for a topic ID
  def get_topic_name(id)
    @topic_map[id]
  end

  # Politely close the connection to the MQTT broker
  def disconnect
    send_packet(MQTT::Packet::Disconnect.new)
    @state = :disconnected
    close_connection_after_writing
  end
end