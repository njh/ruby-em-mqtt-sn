require 'optparse'

class EventMachine::MQTTSN::Gateway
  attr_accessor :local_address
  attr_accessor :local_port
  attr_accessor :server_address
  attr_accessor :server_port
  attr_accessor :logger

  def initialize(args=[])
    # Set defaults
    self.local_address = "0.0.0.0"
    self.local_port = EventMachine::MQTTSN::DEFAULT_PORT
    self.server_address = "127.0.0.1"
    self.server_port = MQTT::DEFAULT_PORT
    self.logger = Logger.new(STDOUT)
    self.logger.level = Logger::INFO
    parse(args) unless args.empty?
  end

  def parse(args)
    OptionParser.new("", 28, '  ') do |opts|
      opts.banner = "Usage: #{File.basename $0} [options]"

      opts.separator ""
      opts.separator "Options:"

      opts.on("-D", "--debug", "turn on debug logging") do
        self.logger.level = Logger::DEBUG
      end

      opts.on("-a", "--address [HOST]", "bind to HOST address (default: #{local_address})") do |address|
        self.local_address = address
      end

      opts.on("-p", "--port [PORT]", "UDP port number to run on (default: #{local_port})") do |port|
        self.local_port = port
      end

      opts.on("-A", "--server-address [HOST]", "MQTT server address to connect to (default: #{server_address})") do |address|
        self.server_address = address
      end

      opts.on("-P", "--server-port [PORT]", "MQTT server port to connect to (default: #{server_port})") do |port|
        self.server_port = port
      end

      opts.on_tail("-h", "--help", "show this message") do
        puts opts
        exit
      end

      opts.on_tail("--version", "show version") do
        puts EventMachine::MQTTSN::VERSION
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

      logger.info("Starting MQTT-SN gateway on UDP #{local_address}:#{local_port}")
      logger.info("MQTT server address #{server_address}:#{server_port}")
      EventMachine.open_datagram_socket(
        local_address,
        local_port,
        EventMachine::MQTTSN::GatewayHandler,
        :logger => logger,
        :server_address => server_address,
        :server_port => server_port
      )
    end
  end

end
