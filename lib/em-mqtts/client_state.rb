
class EventMachine::MQTTS::ClientState
  attr_accessor :connected
  attr_accessor :address
  attr_accessor :port
  attr_accessor :client_id
  attr_accessor :keep_alive
  attr_accessor :topic_map

  def initialize(address, port)
    @connected = false
    @address = address
    @port = port
    @client_id = nil
    @keep_alive = 10
    @topic_map = {}
  end
  

end
