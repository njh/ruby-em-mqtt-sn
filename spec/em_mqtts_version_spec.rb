$:.unshift(File.dirname(__FILE__))

require 'spec_helper'
require 'em/mqtts/version'

describe EventMachine::MQTTS do

  describe "version number" do
    it "should be defined as a constant" do
      defined?(EventMachine::MQTTS::VERSION).should == 'constant'
    end

    it "should be a string" do
      EventMachine::MQTTS::VERSION.should be_a(String)
    end

    it "should be in the format x.y.z" do
      EventMachine::MQTTS::VERSION.should =~ /^\d{1,2}\.\d{1,2}\.\d{1,2}$/
    end
  end

end
