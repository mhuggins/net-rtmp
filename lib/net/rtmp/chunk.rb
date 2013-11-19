module Net
  class RTMP
    class Chunk
      DEFAULT_OPTIONS = { amf_version: 3 }

      HEADER_LENGTHS = {
          0b00 => 12,
          0b01 => 8,
          0b10 => 4,
          0b11 => 1
      }

      MESSAGE_TYPES = {
          0x00 => :none,
          0x01 => :chunk_size,
          0x02 => :abort,
          0x03 => :ack,
          0x04 => :ping,
          0x05 => :ack_size,
          0x06 => :bandwidth,
          0x08 => :audio,
          0x09 => :video,
          0x0f => :flex, # aka AMF3 data
          0x10 => :amf3_shared_object, # documented as kMsgContainer=16
          0x11 => :amf3,
          0x12 => :invoke, # aka AMF0 data
          0x13 => :amf0_shared_object, # documented as kMsgContainer=19
          0x14 => :amf0,
          0x16 => :flv # documented as aggregate
      }

      attr_reader :stream_id, :type, :data

      def initialize(stream_id, type, data)
        self.stream_id = stream_id
        self.type = type
        self.data = data
      end

      def serialize
        # TODO
      end

      private

      def stream_id=(stream_id)
        raise ArgumentError, "stream_id must be a #{Fixnum}" unless stream_id.is_a?(Fixnum)
        @stream_id = stream_id
      end

      def type=(type)
        raise ArgumentError, "type must be a #{Fixnum}" unless type.is_a?(Fixnum)
        @type = type
      end

      def data=(data)
        raise ArgumentError, "data must be a #{String}" unless data.is_a?(String)
        @data = data
      end
    end
  end
end
