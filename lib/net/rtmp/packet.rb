require 'rocketamf'

module Net
  class RTMP
    module Packet
      def self.included(base)
        base.extend ClassMethods
      end

      module ClassMethods
        def as_class(class_name)
          RocketAMF::ClassMapper.define { |mappings| mappings.map ruby: name, as: class_name }
        end
      end
    end
  end
end
