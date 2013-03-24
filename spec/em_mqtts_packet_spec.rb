$:.unshift(File.dirname(__FILE__))

require 'spec_helper'

describe EventMachine::MQTTS::Packet do

  describe "when creating a new packet" do
    it "should allow you to set the packet dup flag as a hash parameter" do
      packet = EventMachine::MQTTS::Packet.new( :duplicate => true )
      packet.duplicate.should be_true
    end

    it "should allow you to set the packet QOS level as a hash parameter" do
      packet = EventMachine::MQTTS::Packet.new( :qos => 2 )
      packet.qos.should == 2
    end

    it "should allow you to set the packet retain flag as a hash parameter" do
      packet = EventMachine::MQTTS::Packet.new( :retain => true )
      packet.retain.should be_true
    end
  end
  
  describe "getting the type id on a un-subclassed packet" do
    it "should throw an exception" do
      lambda {
        EventMachine::MQTTS::Packet.new.type_id
      }.should raise_error(
        RuntimeError,
        "Invalid packet type: EventMachine::MQTTS::Packet"
      )
    end
  end

  describe "Parsing a packet that does not match the packet length" do
    it "should throw an exception" do
      lambda {
        packet = EventMachine::MQTTS::Packet.parse("\x02\x1834567")
      }.should raise_error(
        EventMachine::MQTTS::ProtocolException,
        "Length of packet is not the same as the length header"
      )
    end  
  end  

end


describe EventMachine::MQTTS::Packet::Connect do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Connect.new
    packet.type_id.should == 0x04
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a packet with no flags" do
      packet = EventMachine::MQTTS::Packet::Connect.new(
        :client_id => 'mqtts-client-pub'
      )
      packet.to_s.should == "\026\004\004\001\000\017mqtts-client-pub"
    end

    it "should output the correct bytes for a packet with clean session turned off" do
      packet = EventMachine::MQTTS::Packet::Connect.new(
        :client_id => 'myclient',
        :clean_session => false
      )
      packet.to_s.should == "\016\004\000\001\000\017myclient"
    end

    it "should throw an exception when there is no client identifier" do
      lambda {
        EventMachine::MQTTS::Packet::Connect.new.to_s
      }.should raise_error(
        'Invalid client identifier when serialising packet'
      )
    end

    it "should output the correct bytes for a packet with a will request" do
      packet = EventMachine::MQTTS::Packet::Connect.new(
        :client_id => 'myclient',
        :request_will => true,
        :clean_session => true
      )
      packet.to_s.should == "\016\004\014\001\000\017myclient"
    end

    it "should output the correct bytes for with a custom keep alive" do
      packet = EventMachine::MQTTS::Packet::Connect.new(
        :client_id => 'myclient',
        :request_will => true,
        :clean_session => true,
        :keep_alive => 30
      )
      packet.to_s.should == "\016\004\014\001\000\036myclient"
    end
  end

  describe "when parsing a simple Connect packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse(
        "\026\004\004\001\000\000mqtts-client-pub"
      )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Connect
    end

    it "should not have the request will flag set" do
      @packet.request_will.should be_false
    end

    it "shoul have the clean session flag set" do
      @packet.clean_session.should be_true
    end

    it "should set the Keep Alive timer of the packet correctly" do
      @packet.keep_alive.should == 0
    end

    it "should set the Client Identifier of the packet correctly" do
      @packet.client_id.should == 'mqtts-client-pub'
    end
  end

  describe "when parsing a Connect packet with the clean session flag set" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse(
        "\016\004\004\001\000\017myclient"
      )
    end

    it "should set the clean session flag" do
      @packet.clean_session.should be_true
    end
  end

  describe "when parsing a Connect packet with the will request flag set" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse(
        "\016\004\014\001\000\017myclient"
      )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Connect
    end
    it "should set the Client Identifier of the packet correctly" do
      @packet.client_id.should == 'myclient'
    end

    it "should set the clean session flag should be set" do
      @packet.clean_session.should be_true
    end

    it "should set the Will retain flag should be false" do
      @packet.request_will.should be_true
    end
  end

  context "that has an invalid type identifier" do
    it "should throw an exception" do
      lambda {
        EventMachine::MQTTS::Packet.parse( "\x02\xFF" )
      }.should raise_error(
        EventMachine::MQTTS::ProtocolException,
        "Invalid packet type identifier: 255"
      )
    end
  end

  describe "when parsing a Connect packet an unsupport protocol ID" do
    it "should throw an exception" do
      lambda {
        packet = EventMachine::MQTTS::Packet.parse(
          "\016\004\014\005\000\017myclient"
        )
      }.should raise_error(
        EventMachine::MQTTS::ProtocolException,
        "Unsupported protocol ID number: 5"
      )
    end
  end
end

describe EventMachine::MQTTS::Packet::Connack do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Connack.new
    packet.type_id.should == 0x05
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a sucessful connection acknowledgement packet" do
      packet = EventMachine::MQTTS::Packet::Connack.new( :return_code => 0x00 )
      packet.to_s.should == "\x03\x05\x00"
    end
  end

  describe "when parsing a successful Connection Accepted packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse( "\x03\x05\x00" )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Connack
    end

    it "should set the return code of the packet correctly" do
      @packet.return_code.should == 0x00
    end

    it "should set the return message of the packet correctly" do
      @packet.return_msg.should match(/accepted/i)
    end
  end

  describe "when parsing a congestion packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse( "\x03\x05\x01" )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Connack
    end

    it "should set the return code of the packet correctly" do
      @packet.return_code.should == 0x01
    end

    it "should set the return message of the packet correctly" do
      @packet.return_msg.should match(/rejected: congestion/i)
    end
  end

  describe "when parsing a invalid topic ID packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse( "\x03\x05\x02" )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Connack
    end

    it "should set the return code of the packet correctly" do
      @packet.return_code.should == 0x02
    end

    it "should set the return message of the packet correctly" do
      @packet.return_msg.should match(/rejected: invalid topic ID/i)
    end
  end

  describe "when parsing a 'not supported' packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse( "\x03\x05\x03" )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Connack
    end

    it "should set the return code of the packet correctly" do
      @packet.return_code.should == 0x03
    end

    it "should set the return message of the packet correctly" do
      @packet.return_msg.should match(/not supported/i)
    end
  end

  describe "when parsing an unknown connection refused packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse( "\x03\x05\x10" )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Connack
    end

    it "should set the return code of the packet correctly" do
      @packet.return_code.should == 0x10
    end

    it "should set the return message of the packet correctly" do
      @packet.return_msg.should match(/rejected/i)
    end
  end
end

describe EventMachine::MQTTS::Packet::Register do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Register.new
    packet.type_id.should == 0x0A
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a register packet" do
      packet = EventMachine::MQTTS::Packet::Register.new(
        :topic_id => 0x01,
        :message_id => 0x01,
        :topic_name => 'test'
      )
      packet.to_s.should == "\x0A\x0A\x00\x01\x00\x01test"
    end
  end

  describe "when parsing a Register packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse( "\x0A\x0A\x00\x01\x00\x01test" )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Register
    end

    it "should set the topic id of the packet correctly" do
      @packet.topic_id.should == 0x01
    end

    it "should set the message id of the packet correctly" do
      @packet.message_id.should == 0x01
    end

    it "should set the topic name of the packet correctly" do
      @packet.topic_name.should == 'test'
    end
  end
end


describe EventMachine::MQTTS::Packet::Regack do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Regack.new
    packet.type_id.should == 0x0B
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a register packet" do
      packet = EventMachine::MQTTS::Packet::Regack.new(
        :topic_id => 0x01,
        :message_id => 0x02,
        :return_code => 0x03
      )
      packet.to_s.should == "\x07\x0B\x00\x01\x00\x02\x03"
    end
  end

  describe "when parsing a Register packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse( "\x07\x0B\x00\x01\x00\x02\x03" )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Regack
    end

    it "should set the topic id of the packet correctly" do
      @packet.topic_id.should == 0x01
    end

    it "should set the message id of the packet correctly" do
      @packet.message_id.should == 0x02
    end

    it "should set the topic name of the packet correctly" do
      @packet.return_code.should == 0x03
    end
  end
end


describe EventMachine::MQTTS::Packet::Publish do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Publish.new
    packet.type_id.should == 0x0C
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a publish packet" do
      packet = EventMachine::MQTTS::Packet::Publish.new(
        :topic_id => 0x01,
        :data => "Hello World"
      )
      packet.to_s.should == "\x12\x0C\x00\x00\x01\x00\x00Hello World"
    end
  end

  describe "when parsing a Publish packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse(
        "\x12\x0C\x00\x00\x01\x00\x00Hello World"
      )
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Publish
    end

    it "should set the QOS of the packet correctly" do
      @packet.qos.should === 0
    end

    it "should set the QOS of the packet correctly" do
      @packet.duplicate.should === false
    end

    it "should set the retain flag of the packet correctly" do
      @packet.retain.should === false
    end

    it "should set the topic id of the packet correctly" do
      @packet.topic_id.should === 0x01
    end

    it "should set the message id of the packet correctly" do
      @packet.message_id.should === 0x0000
    end

    it "should set the topic name of the packet correctly" do
      @packet.data.should == "Hello World"
    end
  end

end


describe EventMachine::MQTTS::Packet::Disconnect do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Disconnect.new
    packet.type_id.should == 0x18
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a disconnect packet" do
      packet = EventMachine::MQTTS::Packet::Disconnect.new
      packet.to_s.should == "\x02\x18"
    end
  end

  describe "when parsing a Disconnect packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse("\x02\x18")
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Disconnect
    end
  end
end


describe EventMachine::MQTTS::Packet::Pingreq do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Pingreq.new
    packet.type_id.should == 0x16
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a pingreq packet" do
      packet = EventMachine::MQTTS::Packet::Pingreq.new
      packet.to_s.should == "\x02\x16"
    end
  end

  describe "when parsing a Pingreq packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse("\x02\x16")
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Pingreq
    end
  end
end


describe EventMachine::MQTTS::Packet::Pingresp do
  it "should have the right type id" do
    packet = EventMachine::MQTTS::Packet::Pingresp.new
    packet.type_id.should == 0x17
  end

  describe "when serialising a packet" do
    it "should output the correct bytes for a pingresp packet" do
      packet = EventMachine::MQTTS::Packet::Pingresp.new
      packet.to_s.should == "\x02\x17"
    end
  end

  describe "when parsing a Pingresp packet" do
    before(:each) do
      @packet = EventMachine::MQTTS::Packet.parse("\x02\x17")
    end

    it "should correctly create the right type of packet object" do
      @packet.class.should == EventMachine::MQTTS::Packet::Pingresp
    end
  end
end
