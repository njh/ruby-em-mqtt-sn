$:.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'mqtt'

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

end
