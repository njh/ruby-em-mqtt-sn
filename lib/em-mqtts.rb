require 'eventmachine'
require 'logger'
require 'mqtt'

require "em-mqtts/version"

module EventMachine::MQTTS

  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = 1883

  autoload :ClientConnection, 'em-mqtts/client_connection'
  autoload :Connection,       'em-mqtts/connection'
  autoload :Gateway,          'em-mqtts/gateway'
  autoload :Packet,           'em-mqtts/packet'
  autoload :ServerConnection, 'em-mqtts/server_connection'

end
