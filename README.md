# Net::Rtmp

TODO: Write a gem description

## Installation

Add this line to your application's Gemfile:

    gem 'net-rtmp'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install net-rtmp

## Usage

Create a new `Net::RTMP` client by passing it a valid `URI` object.  This will
automatically attempt to connect to the server and perform the RTMP handshake
process.

    uri = URI.parse('http://wwww.example.com:2099')
    client = Net::RTMP.new(uri)

The initializer method will return normally if the connection & handshake are
both successful.  Otherwise, an exception will be thrown.

Helper methods exist to determine the state of the connection.

    client.connected?    # => true/false
    client.closed?       # => true/false

Sending data is done through the `write` method, which expects a
`Net::RTMP::Packet`.

    packet = MyCustomPacket.new( ... )
    client.write(packet)

Receiving data is done through the `read` method, which returns a
`Net::RTMP::Packet`.

    packet_id = 1
    packet = client.read(packet_id)

### Packets

Packets can represent any type of object and must map to a class on the RTMP
server.

    class AuthenticationPacket
      include Net::RTMP::Packet

      as_class 'com.something.UserCredentials'

      attr_reader :username, :password

      def initialize(username, password)
        @username = username
        @password = password
      end
    end

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
