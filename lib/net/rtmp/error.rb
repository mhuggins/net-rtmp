module Net
  class RTMP
    class ServerError < StandardError; end
    class ClientError < StandardError; end
    class HandshakeError < StandardError; end
  end
end
