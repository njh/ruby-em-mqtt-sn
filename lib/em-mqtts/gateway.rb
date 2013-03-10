require 'optparse'

class EventMachine::MQTTS::Gateway
  attr_accessor :address
  attr_accessor :port
  attr_accessor :logger

  def initialize(args=[])
    # Set defaults
    self.mqtts_address = "0.0.0.0"
    self.mqtts_port = EventMachine::MQTTS::DEFAULT_PORT
    self.broker_address = "127.0.0.1"
    self.broker_port = MQTT::DEFAULT_PORT
    self.logger = Logger.new(STDOUT)
    self.logger.level = Logger::INFO
    parse(args) unless args.empty?
  end

  def parse(args)
    OptionParser.new("", 24, '  ') do |opts|
      opts.banner = "Usage: #{File.basename $0} [options]"

      opts.separator ""
      opts.separator "Options:"

      opts.on("-D", "--debug", "turn on debug logging") do
        self.logger.level = Logger::DEBUG
      end

      opts.on("-a", "--address [HOST]", "bind to HOST address (default: #{address})") do |address|
        self.address = address
      end

      opts.on("-p", "--port [PORT]", "port number to run on (default: #{port})") do |port|
        self.port = port
      end

      opts.on_tail("-h", "--help", "show this message") do
        puts opts
        exit
      end

      opts.on_tail("--version", "show version") do
        puts EventMachine::MQTTS::VERSION
        exit
      end

      opts.parse!(args)
    end
  end

  def run
    EventMachine.run do
      # hit Control + C to stop
      Signal.trap("INT")  { EventMachine.stop }
      Signal.trap("TERM") { EventMachine.stop }

      logger.info("Starting MQTT-S gateway on UDP #{address}:#{port}")
      EventMachine.start_server(address, port, EventMachine::MQTTS::ServerConnection, logger)
    end
  end

end
