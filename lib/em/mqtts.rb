$:.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..')))

require 'eventmachine'
require 'logger'
require 'em/mqtt'

module EventMachine::MQTTS

  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = 1883

  class Exception < Exception
  end

  class ProtocolException < MQTT::Exception
  end

  require "em/mqtts/version"

  autoload :BrokerConnection,  'em/mqtts/broker_connection'
  autoload :Gateway,           'em/mqtts/gateway'
  autoload :GatewayHandler,    'em/mqtts/gateway_handler'
  autoload :Packet,            'em/mqtts/packet'

end
