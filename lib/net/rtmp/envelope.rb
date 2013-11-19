require 'rocketamf'
require 'net/rtmp/chunk'
require 'net/rtmp/envelope/header'
require 'net/rtmp/envelope/message'

module Net
  class RTMP
    class Envelope < RocketAMF::Envelope
      def chunks(chunk_size = 128)
        data = serialize
        total_chunks = (data.size / chunk_size.to_f).ceil

        stream_id = 1   # TODO what should this be?
        chunk_type = 1  # TODO what should this be?

        total_chunks.times.map do |i|
          chunk_start = chunk_size * i
          chunk_end = chunk_start + chunk_size - 1

          Chunk.new(stream_id, chunk_type, data[chunk_start..chunk_end])
        end
      end

      private

      def header_length_for_chunk(offset)
        offset == 0 ? 12 : 1
      end
    end
  end
end
