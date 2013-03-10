#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)+'/../lib'

require 'rubygems'
require 'em-mqtts'

EventMachine.run do
  EventMachine::MQTTS::ClientConnection.connect('localhost') do |c|
    c.subscribe('test')
    c.receive_callback do |message|
      p message
    end
  end
end
