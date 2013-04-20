ruby-em-mqtts
=============

This gem adds MQTT-S (MQTT For Sensor Networks) protocol support to EventMachine,
an event-processing library for Ruby.

It also includes a MQTT-S gateway, to connect MQTT-S clients to a standard [MQTT] broker.

    Usage: em-mqtts-gateway [options]

    Options:
      -D, --debug                  turn on debug logging
      -a, --address [HOST]         bind to HOST address (default: 0.0.0.0)
      -p, --port [PORT]            UDP port number to run on (default: 1883)
      -A, --broker-address [HOST]  MQTT broker address to connect to (default: 127.0.0.1)
      -P, --broker-port [PORT]     MQTT broker port to connect to (default: 1883)
      -h, --help                   show this message
          --version                show version


Example
-------

    $ sudo gem install em-mqtts
    $ em-mqtts-gateway -A test.mosquitto.org
    I, [2013-04-20T12:08:56.850572 #29588]  INFO -- : Starting MQTT-S gateway on UDP 0.0.0.0:1883
    I, [2013-04-20T12:08:56.850646 #29588]  INFO -- : Broker address test.mosquitto.org:1883
    I, [2013-04-20T12:09:00.577446 #29588]  INFO -- : mqtts-tools-29710 is now connected
    I, [2013-04-20T12:09:00.578032 #29588]  INFO -- : mqtts-tools-29710 subscribing to 'test'
    I, [2013-04-20T12:09:00.601937 #29588]  INFO -- : mqtts-tools-29710 recieved publish to 'test'
    I, [2013-04-20T12:09:07.770269 #29588]  INFO -- : mqtts-tools-29713 is now connected
    I, [2013-04-20T12:09:07.770733 #29588]  INFO -- : mqtts-tools-29713 publishing to 'test'
    I, [2013-04-20T12:09:07.783940 #29588]  INFO -- : mqtts-tools-29710 recieved publish to 'test'
    I, [2013-04-20T12:09:22.815726 #29588]  INFO -- : Disconnected: mqtts-tools-29713


Contact
-------

* Author:    Nicholas J Humfrey
* Email:     njh@aelius.com
* Twitter:   [@njh]
* Home Page: http://www.aelius.com/njh/
* License:   Distributes under the same terms as Ruby


[MQTT]:                     http://mqtt.org/
[@njh]:                     http://twitter.com/njh
