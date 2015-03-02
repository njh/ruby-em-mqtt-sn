$:.unshift(File.dirname(__FILE__))

require 'spec_helper'

describe EventMachine::MQTTSN do

  describe "version number" do
    it "should be defined as a constant" do
      expect(defined?(EventMachine::MQTTSN::VERSION)).to eq('constant')
    end

    it "should be a string" do
      expect(EventMachine::MQTTSN::VERSION).to be_a(String)
    end

    it "should be in the format x.y.z" do
      expect(EventMachine::MQTTSN::VERSION).to match(/^\d{1,2}\.\d{1,2}\.\d{1,2}$/)
    end
  end

end
