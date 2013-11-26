module Net
  class RTMP
    class Chunk
      DEFAULT_OPTIONS = { amf_version: 3 }

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

      attr_reader :message_stream_id, :message_type_id, :chunk_stream_id, :chunk_type, :timestamp, :data

      def initialize(options)
        self.message_stream_id = options[:message_stream_id]
        self.message_type_id = options[:message_type_id]
        self.chunk_stream_id = options[:chunk_stream_id]
        self.chunk_type = options[:chunk_type]
        self.timestamp = options[:timestamp]
        self.data = options[:data]
      end

      def serialize
        ''.tap do |buffer|
          buffer << basic_header
          buffer << message_header
          buffer << extended_timestamp
          buffer << data
        end
      end

      protected

      def message_stream_id=(message_stream_id)
        raise ArgumentError, "message_stream_id must be a #{Fixnum}" unless message_stream_id.is_a?(Fixnum)
        @message_stream_id = message_stream_id
      end

      def message_type_id=(message_type_id)
        raise ArgumentError, "message_type_id must be a #{Fixnum}" unless message_type_id.is_a?(Fixnum)
        @message_type_id = message_type_id
      end

      def chunk_stream_id=(chunk_stream_id)
        raise ArgumentError, "chunk_stream_id must be a #{Fixnum}" unless chunk_stream_id.is_a?(Fixnum)
        @chunk_stream_id = chunk_stream_id
      end

      def chunk_type=(chunk_type)
        raise ArgumentError, "chunk_type must be a #{Fixnum}" unless chunk_type.is_a?(Fixnum)
        @chunk_type = chunk_type
      end

      def data=(data)
        raise ArgumentError, "data must be a #{String}" unless data.is_a?(String)
        @data = data
      end

      def timestamp=(timestamp)
        raise ArgumentError, "timestamp must be a #{Fixnum}" unless timestamp.is_a?(Fixnum)
        @timestamp = timestamp
      end

      private

      # Basic Header (1 to 3 bytes): This field encodes the chunk stream ID
      #    and the chunk type. Chunk type determines the format of the
      #    encoded message header. The length depends entirely on the chunk
      #    stream ID, which is a variable-length field.
      def basic_header
        case chunk_stream_id
          when 2..63
            [((chunk_type & 0x2) << 7) | (chunk_stream_id & 0x6)].pack('C')
          when 64..319
            [((chunk_type & 0x2) << 7) | 0x0].pack('C') + [chunk_stream_id - 64].pack('C')
          when 320..65599
            [((chunk_type & 0x2) << 7) | 0x1].pack('C') + [chunk_stream_id - 64].pack('S')
          else
            raise ArgumentError, "invalid chunk stream ID `#{chunk_stream_id}`"
        end
      end

      # Message Header (0, 3, 7, or 11 bytes): This field encodes
      #    information about the message being sent (whether in whole or in
      #    part). The length can be determined using the chunk type
      #    specified in the chunk header.
      def message_header
        ''.tap do |buffer|
          # timestamp, or timestamp delta for chunk types 1 & 2 (3 bytes)
          if [0, 1, 2].include?(chunk_type)
            if extended_timestamp?
              buffer << [0xFF].pack('C')
              buffer << [0xFFFF].pack('S')
            else
              buffer << [(timestamp & 0xFF0000) >> 16].pack('C')
              buffer << [(timestamp & 0x00FFFF)].pack('S')
            end
          end

          # message length (3 bytes) and message type id (1 byte)
          if [0, 1].include?(chunk_type)
            buffer << [((data.size & 0x18) << 8) | (message_type_id & 0x8)].pack('L')
          end

          # message stream id (4 bytes)
          if [0].include?(chunk_type)
            buffer << [message_stream_id].pack('L')
          end
        end
      end

      # Extended Timestamp (0 or 4 bytes): This field is present in certain
      #    circumstances depending on the encoded timestamp or timestamp
      #    delta field in the Chunk Message header. See Section 5.3.1.3 for
      #    more information.
      def extended_timestamp
        if extended_timestamp?
          [timestamp & 0xFFFFFFFF].pack('L')
        else
          ''
        end
      end

      def extended_timestamp?
        timestamp >= 0xFFFFFF
      end
    end
  end
end
