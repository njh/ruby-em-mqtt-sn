module EventMachine::MQTTS

  # Class representing a MQTTS Packet
  # Performs binary encoding and decoding of headers
  class Packet
    attr_accessor :duplicate     # Duplicate delivery flag
    attr_accessor :qos           # Quality of Service level
    attr_accessor :retain        # Retain flag
    attr_accessor :request_will  # Request that gateway prompts for Will
    attr_accessor :clean_session # When true, subscriptions are deleted after disconnect
    attr_accessor :topic_id_type # One of :topic_id, :pre_defined or :short_name

    DEFAULTS = {}

    # Parse buffer into new packet object
    def self.parse(buffer)
      # Parse the fixed header (length and type)
      length,type_id,body = buffer.unpack('CCa*')
      if length == 1
        length,type_id,body = buffer.unpack('xnCa*')
      end

      # Double-check the length
      if buffer.length != length
        raise ProtocolException.new("Length of packet is not the same as the length header")
      end

      packet_class = PACKET_TYPES[type_id]
      if packet_class.nil?
        raise ProtocolException.new("Invalid packet type identifier: #{type_id}")
      end

      # Create a new packet object
      packet = packet_class.new
      packet.parse_body(body)

      return packet
    end

    # Create a new empty packet
    def initialize(args={})
      update_attributes(self.class::DEFAULTS.merge(args))
    end

    def update_attributes(attr={})
      attr.each_pair do |k,v|
        send("#{k}=", v)
      end
    end

    # Get the identifer for this packet type
    def type_id
      PACKET_TYPES.each_pair do |key, value|
        return key if self.class == value
      end
      raise "Invalid packet type: #{self.class}"
    end

    # Serialise the packet
    def to_s
      # Get the packet's variable header and payload
      body = self.encode_body

      # Build up the body length field bytes
      body_length = body.length
      if body_length > 65531
        raise "Packet too big"
      elsif body_length > 253
        [0x01, body_length + 4, type_id].pack('CnC') + body
      else
        [body_length + 2, type_id].pack('CC') + body
      end
    end

    protected
    
    def parse_flags(flags)
      self.duplicate = ((flags & 0x80) >> 7) == 0x01
      self.qos = (flags & 0x60) >> 5
      self.qos = -1 if self.qos == 3
      self.retain = ((flags & 0x10) >> 4) == 0x01
      self.request_will = ((flags & 0x08) >> 3) == 0x01
      self.clean_session = ((flags & 0x04) >> 2) == 0x01
      self.topic_id_type = (flags & 0x03)
    end

    def parse_body(buffer)
    end

    # Get serialisation of packet's body (variable header and payload)
    def encode_body
      '' # No body by default
    end
    
    def encode_flags
      flags = 0x00
      flags += 0x80 if duplicate
      flags += 0x10 if retain
      flags += 0x08 if request_will
      flags += 0x04 if clean_session
      return flags
    end

    class Connect < Packet
      attr_accessor :keep_alive
      attr_accessor :client_id

      DEFAULTS = {
        :request_will => false,
        :clean_session => true,
        :keep_alive => 15
      }

      # Get serialisation of packet's body
      def encode_body
        body = ''
        if @client_id.nil? or @client_id.length < 1 or @client_id.length > 23
          raise "Invalid client identifier when serialising packet"
        end

        body += [encode_flags, 0x01, keep_alive].pack('CCn')
        body += client_id
        return body
      end

      def parse_body(buffer)
        flags,protocol_id,duration,client_id = buffer.unpack('CCna*')

        if protocol_id != 0x01
          raise ProtocolException.new("Unsupported protocol ID number: #{protocol_id}")
        end

        parse_flags(flags)
        self.keep_alive = duration
        self.client_id = client_id
      end
    end

    class Connack < Packet
    end

    class Register < Packet
    end

    class Regack < Packet
    end

    class Publish < Packet
    end

    class Disconnect < Packet
    end

  end


  # An enumeration of the MQTT-S packet types
  PACKET_TYPES = {
#       0x00 => EventMachine::MQTTS::Packet::Advertise,
#       0x01 => EventMachine::MQTTS::Packet::Searchgw,
#       0x02 => EventMachine::MQTTS::Packet::Gwinfo,
      0x04 => EventMachine::MQTTS::Packet::Connect,
      0x05 => EventMachine::MQTTS::Packet::Connack,
#       0x06 => EventMachine::MQTTS::Packet::Willtopicreq,
#       0x07 => EventMachine::MQTTS::Packet::Willtopic,
#       0x08 => EventMachine::MQTTS::Packet::Willmsgreq,
#       0x09 => EventMachine::MQTTS::Packet::Willmsg,
      0x0a => EventMachine::MQTTS::Packet::Register,
      0x0b => EventMachine::MQTTS::Packet::Regack,
      0x0c => EventMachine::MQTTS::Packet::Publish,
#       0x0d => EventMachine::MQTTS::Packet::Puback,
#       0x0e => EventMachine::MQTTS::Packet::Pubcomp,
#       0x0f => EventMachine::MQTTS::Packet::Pubrec,
#       0x10 => EventMachine::MQTTS::Packet::Pubrel,
#       0x12 => EventMachine::MQTTS::Packet::Subscribe,
#       0x13 => EventMachine::MQTTS::Packet::Suback,
#       0x14 => EventMachine::MQTTS::Packet::Unsubscribe,
#       0x15 => EventMachine::MQTTS::Packet::Unsuback,
#       0x16 => EventMachine::MQTTS::Packet::Pingreq,
#       0x17 => EventMachine::MQTTS::Packet::Pingresp,
      0x18 => EventMachine::MQTTS::Packet::Disconnect,
#       0x1a => EventMachine::MQTTS::Packet::Willtopicupd,
#       0x1b => EventMachine::MQTTS::Packet::Willtopicresp,
#       0x1c => EventMachine::MQTTS::Packet::Willmsgupd,
#       0x1d => EventMachine::MQTTS::Packet::Willmsgresp,
  }

end