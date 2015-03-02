ruby-em-mqtt-sn
===============

This gem adds MQTT-SN (MQTT For Sensor Networks) protocol support to EventMachine,
an event-processing library for Ruby.

It also includes a MQTT-SN gateway, to connect MQTT-SN clients to a standard [MQTT] server.

    Usage: em-mqtt-sn-gateway [options]

    Options:
      -D, --debug                  turn on debug logging
      -a, --address [HOST]         bind to HOST address (default: 0.0.0.0)
      -p, --port [PORT]            UDP port number to run on (default: 1883)
      -A, --server-address [HOST]  MQTT server address to connect to (default: 127.0.0.1)
      -P, --server-port [PORT]     MQTT server port to connect to (default: 1883)
      -h, --help                   show this message
          --version                show version


Example
-------

    $ sudo gem install em-mqtt-sn
    $ em-mqtt-sn-gateway -A test.mosquitto.org
    I, [2013-04-20T12:08:56.850572 #29588]  INFO -- : Starting MQTT-SN gateway on UDP 0.0.0.0:1883
    I, [2013-04-20T12:08:56.850646 #29588]  INFO -- : Server address test.mosquitto.org:1883
    I, [2013-04-20T12:09:00.577446 #29588]  INFO -- : mqtt-sn-tools-29710 is now connected
    I, [2013-04-20T12:09:00.578032 #29588]  INFO -- : mqtt-sn-tools-29710 subscribing to 'test'
    I, [2013-04-20T12:09:00.601937 #29588]  INFO -- : mqtt-sn-tools-29710 recieved publish to 'test'
    I, [2013-04-20T12:09:07.770269 #29588]  INFO -- : mqtt-sn-tools-29713 is now connected
    I, [2013-04-20T12:09:07.770733 #29588]  INFO -- : mqtt-sn-tools-29713 publishing to 'test'
    I, [2013-04-20T12:09:07.783940 #29588]  INFO -- : mqtt-sn-tools-29710 recieved publish to 'test'
    I, [2013-04-20T12:09:22.815726 #29588]  INFO -- : Disconnected: mqtt-sn-tools-29713


License
-------

The em-mqtt-sn gem is licensed under the terms of the MIT license.
See the file LICENSE for details.


Contact
-------

* Author:    Nicholas J Humfrey
* Email:     njh@aelius.com
* Twitter:   [@njh]
* Home Page: http://www.aelius.com/njh/


[MQTT]:                     http://mqtt.org/
[@njh]:                     http://twitter.com/njh
