require 'uri'
require 'openssl'
require 'socket'
require 'timeout'

require 'net/rtmp/envelope'
require 'net/rtmp/envelope/connect_request'
require 'net/rtmp/error'
require 'net/rtmp/packet'
require 'net/rtmp/version'

module Net
  class RTMP
    DEFAULT_OPTIONS = { version: 3, timeout: 15, chunk_size: 128 }.freeze

    attr_reader :uri, :version, :timeout, :chunk_size

    def initialize(uri, options = {})
      options = DEFAULT_OPTIONS.merge(options)

      self.uri = uri.dup.freeze
      self.timeout = options[:timeout]
      self.version = options[:version]
      self.chunk_size = options[:chunk_size]

      connect
      read_async
    end

    def connected?
      !closed?
    end

    def closed?
      socket.closed?
    end

    def close
      socket.read_nonblock
      socket.close if connected?
    end

    def send_connect_request(&block)
      envelope = ConnectRequest.new('', "rtmps://#{uri.host}:#{uri.port}", 'app:/mod_ser.dat', amf_version: version)
      write(envelope, &block)
    end

    def write(envelope, &block)
      raise ArgumentError, "must be a #{Envelope} object" unless envelope.is_a?(Envelope)

      callbacks[next_id] = block

      envelope.chunks(chunk_size) do |chunk|
        socket.write(chunk)
      end
    end

    private

    def uri=(uri)
      raise ArgumentError, 'invalid URI' unless uri.is_a?(URI)
      @uri = uri
    end

    def timeout=(timeout)
      raise ArgumentError, 'invalid timeout' unless timeout.is_a?(Numeric)
      @timeout = timeout
    end

    def version=(version)
      raise ArgumentError, 'invalid version' unless [0, 3].include?(version)
      @version = version
    end

    def chunk_size=(chunk_size)
      raise ArgumentError, 'invalid chunk size' unless chunk_size.is_a?(Fixnum) && chunk_size > 0
      #logger.warn 'chunk size should be at least 128 bytes' if chunk_size < 128
      @chunk_size = chunk_size
    end

    def socket
      @socket ||= begin
        socket_timeout = [timeout, 0].pack('l_*')

        tcp_socket = Timeout.timeout(timeout) { TCPSocket.new(uri.host, uri.port) }
        tcp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_RCVTIMEO, socket_timeout)
        tcp_socket.setsockopt(Socket::SOL_SOCKET, Socket::SO_SNDTIMEO, socket_timeout)

        context = OpenSSL::SSL::SSLContext.new
        context.set_params(ssl_version: :TLSv1, verify_mode: OpenSSL::SSL::VERIFY_PEER)

        OpenSSL::SSL::SSLSocket.new(tcp_socket, context).tap { |socket| socket.sync_close = true }
      end
    end

    def connect
      socket.connect

      raise ServerError, 'Cannot connect to server.' if socket.closed?

      # perform standard RTMP handshake
      unless handshake
        disconnect
        raise HandshakeError, 'Server returned invalid handshake.'
      end

      true
    end

    def handshake
      package_size = 1536

      # Deliver C0 chunk of the RTMP specification.
      # C0 chunk: 8-bit RTMP version requested by client (8-bit total)
      message = [version].pack('C')
      socket.write(message)

      # Deliver C1 chunk of the RTMP specification.
      # C1 chunk: 4-byte time (ms since epoch), 4-byte zero representation, & 1528-byte random data (1536-byte total)
      random_data = Random.new.bytes(package_size - 8)
      message = ''
      message << [time_since_epoch].pack('L')
      message << [0x0].pack('L')
      message << random_data
      socket.write(message)

      # Receive S0 chunk of the RTMP specification.
      # S0 chunk: 8-bit RTMP version implemented by server
      response = socket.read(1)
      self.version = response.unpack('C').first

      # Receive S1 chunk of the RTMP specification.
      # S1 chunk: 4-byte server time (ms since epoch), 4-byte client time, & 1528-byte mirror of C1 data
      response = socket.read(package_size)
      server_time_since_epoch = response[0..3].unpack('L').first

      # Deliver C2 chunk of the RTMP specification in the second message.
      # C2 chunk: 32-byte server time, 32-byte current client time, & 1528-byte S1 response data (1536-byte total)
      message = ''
      message << [server_time_since_epoch].pack('L')
      message << [time_since_epoch].pack('L')
      message << response[8..response.size]

      socket.write(message)

      # Receive S2 chunk of the RTMP specification in first response.
      # S2 chunk: 32-byte client time, 32-byte current server time, & 1528-byte C2 request data (1536-byte total)
      response = socket.read(package_size)

      # Validate S2 response data matches original random data.
      response[8..package_size] == random_data
    end

    def read_async
      thread = Thread.new do
        read while connected?
      end

      thread.abort_on_exception = true
      thread.run
    end

    def read
      while (data = socket.read_nonblock(chunk_size) rescue nil)
        buffer << data
      end

      while message_available?(buffer)
        envelope = RocketAMF::Envelope.new.populate_from_stream(buffer)
        received(envelope)
      end
    end

    def message_available?(buffer)
      false  # TODO manually determine if `buffer` contains a full RTMP message
    end

    def received(message)
      obj = RocketAMF.deserialize(message, version)

      if obj.name == '_error'
        close
      else
        callback = @callbacks.delete(obj.id)
        callback.call(obj) if callback
      end
    end

    def time_since_epoch
      (Time.now.to_f * 1000).to_i
    end

    def buffer
      @buffer ||= ''
    end

    def callbacks
      @callbacks ||= {}
    end

    def next_id
      @next_id ||= 0
      @next_id += 1
    end
  end
end
