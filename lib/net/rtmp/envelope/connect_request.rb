require 'net/rtmp/envelope'

module Net
  class RTMP
    class ConnectRequest < Envelope
      def initialize(app, tc_url, swf_url, options = {})
        super(options)

        body = {
            app: app,
            flashVer: 'WIN 10,1,85,3',
            swfUrl: swf_url,
            tcUrl: tc_url,
            fpad: false,
            capabilities: 239,
            audioCodecs: 3191,
            videoCodecs: 252,
            videoFunction: 1,
            pageUrl: nil,
            objectEncoding: 3,
        }

        command = RocketAMF::Values::CommandMessage.new
        command.operation = RocketAMF::Values::CommandMessage::CLIENT_PING_OPERATION
        command.headers = { DSMessagingVersion: 1, DSId: 'my-rtmps' }

        header = Header.new('command', true, channel_id: 3, message_type: :amf0)
        message = Message.new('', '', body)

        headers << header
        messages << message
      end
    end
  end
end
