#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)+'/../lib'

require 'rubygems'
require 'em-mqtt-sn'

EventMachine.run do
  EventMachine::MQTTSN::ClientConnection.connect('localhost') do |c|
    c.subscribe('test')
    c.receive_callback do |message|
      p message
    end
  end
end
