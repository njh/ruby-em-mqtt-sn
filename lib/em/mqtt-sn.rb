$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))

require 'eventmachine'
require 'logger'
require 'em/mqtt'

module EventMachine::MQTTSN

  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = 1883

  class Exception < Exception
  end

  class ProtocolException < MQTT::Exception
  end

  require "em/mqtt-sn/version"

  autoload :ServerConnection,  'em/mqtt-sn/server_connection'
  autoload :Gateway,           'em/mqtt-sn/gateway'
  autoload :GatewayHandler,    'em/mqtt-sn/gateway_handler'
  autoload :Packet,            'em/mqtt-sn/packet'

end
