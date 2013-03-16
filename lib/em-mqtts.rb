require 'eventmachine'
require 'logger'
require 'em-mqtt'

require "em-mqtts/version"

module EventMachine::MQTTS

  DEFAULT_HOST = 'localhost'
  DEFAULT_PORT = 1883

  class Exception < Exception
  end

  class ProtocolException < MQTT::Exception
  end

  autoload :ClientState,       'em-mqtts/client_state'
  autoload :Gateway,           'em-mqtts/gateway'
  autoload :GatewayConnection, 'em-mqtts/gateway_connection'
  autoload :Packet,            'em-mqtts/packet'

end
