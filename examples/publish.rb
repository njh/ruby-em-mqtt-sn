#!/usr/bin/env ruby

$:.unshift File.dirname(__FILE__)+'/../lib'

require 'rubygems'
require 'em-mqtts'

include EventMachine::MQTTS

EventMachine.run do
  c = ClientConnection.connect('localhost')
  EventMachine::PeriodicTimer.new(1.0) do
    puts "-- Publishing time"
    c.publish('test', "The time is #{Time.now}")
  end
end
