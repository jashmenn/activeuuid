module UUIDTools
  class UUID
    # monkey-patch Friendly::UUID to serialize UUIDs to MySQL
    def quoted_id
      s = raw.unpack("H*")[0]
      "x'#{s}'"
    end
  end
end

module ActiveUUID
  class UUIDSerializer
    def load(binary)
      case binary
        when UUIDTools::UUID then binary
        when nil then nil
        else UUIDTools::UUID.parse_raw(binary)
      end
    end
    def dump(uuid)
      uuid ? uuid.raw : nil
    end
  end

  module UUID
    extend ActiveSupport::Concern

    included do
      before_create :generate_uuid_if_needed

      set_primary_key "id"
      serialize :id, ActiveUUID::UUIDSerializer.new

      
      def generate_uuid_if_needed
        generate_uuid unless self.id
      end

      def generate_uuid
        self.id = UUIDTools::UUID.timestamp_create
      end
    end

    module ClassMethods
      #def uuids(*attributes)
      #  attributes.each do |attribute|
      #    class_eval <<-eos
      #      # def #{@association_name}
      #      #   @_#{@association_name} ||= self.class.associations[:#{@association_name}].new_proxy(self)
      #      # end
      #    eos
      #  end
      #end
    end

    module InstanceMethods
    end
 
  end
end
