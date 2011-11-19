module UUIDTools
  class UUID
    # monkey-patch Friendly::UUID to serialize UUIDs to MySQL
    def quoted_id
      s = raw.unpack("H*")[0]
      "x'#{s}'"
    end

    def as_json(options = nil)
      hexdigest.upcase
    end

    def to_param
      hexdigest.upcase
    end
  end
end

module Arel
  module Visitors
    class DepthFirst < Arel::Visitors::Visitor
      def visit_UUIDTools_UUID(o)
        o.quoted_id
      end
    end
    class MySQL < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o)
        o.quoted_id
      end
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

      def to_param
        id.to_param
      end

      def generate_uuid
        if nka = self.class.natural_key_attributes
          # TODO if all the attributes return nil you might want to warn about this
          chained = nka.collect{|a| self.send(a).to_s}.join("-")
          self.id = UUIDTools::UUID.sha1_create(UUIDTools::UUID_OID_NAMESPACE, chained)
        else
          self.id = UUIDTools::UUID.timestamp_create
        end
      end
    end

    module ClassMethods
      def natural_key_attributes
        @_activeuuid_natural_key_attributes
      end

      def natural_key(*attributes)
        @_activeuuid_natural_key_attributes = attributes
      end

      def uuids(*attributes)
       attributes.each do |attribute|
          serialize attribute.intern, ActiveUUID::UUIDSerializer.new
         #class_eval <<-eos
         #  # def #{@association_name}
         #  #   @_#{@association_name} ||= self.class.associations[:#{@association_name}].new_proxy(self)
         #  # end
         #eos
       end
      end
    end

    module InstanceMethods
    end
 
  end
end
