require 'uuidtools'

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

    class SQLite < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o)
        o.quoted_id
      end
    end

    class PostgreSQL < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o)
       s = o.raw.unpack("H*")[0]
       "E'\\\\x#{s}'"
      end
    end
  end
end

module ActiveUUID
  class UUIDSerializer
    def load(binary)
      case binary
      when UUIDTools::UUID
        binary
      when String
        parse_string(binary)
      when nil
        nil
      else
        raise TypeError, "the given type cannot be serialized"
      end
    end

    def dump(uuid)
      case uuid
      when UUIDTools::UUID
        uuid.raw
      when String
        parse_string(uuid).raw
      when nil
        nil
      else
        raise TypeError, "the given type cannot be serialized"
      end
    end

    private

    def parse_string str
      return nil if str.blank?
      if str.length == 36
        UUIDTools::UUID.parse str
      elsif str.length == 32
        UUIDTools::UUID.parse_hexdigest str
      else
        UUIDTools::UUID.parse_raw str
      end
    end
  end

  module UUID
    extend ActiveSupport::Concern

    included do
      uuids :id
      before_create :generate_uuids_if_needed
    end

    module ClassMethods
      def natural_key_attributes
        @_activeuuid_natural_key_attributes
      end

      def natural_key(*attributes)
        @_activeuuid_natural_key_attributes = attributes
      end

      def uuid_attributes
        @_activeuuid_attributes
      end

      def uuid_generator(generator_name=nil)
        @_activeuuid_kind = generator_name if generator_name
        @_activeuuid_kind || :random
      end

      def uuids(*attributes)
        @_activeuuid_attributes = attributes.collect(&:intern).each do |attribute|
          serialize attribute.intern, ActiveUUID::UUIDSerializer.new
        end
         #class_eval <<-eos
         #  # def #{@association_name}
         #  #   @_#{@association_name} ||= self.class.associations[:#{@association_name}].new_proxy(self)
         #  # end
         #eos
      end
    end

    def create_uuid
      if nka = self.class.natural_key_attributes
        # TODO if all the attributes return nil you might want to warn about this
        chained = nka.collect{|a| self.send(a).to_s}.join("-")
        UUIDTools::UUID.sha1_create(UUIDTools::UUID_OID_NAMESPACE, chained)
      else
        case self.class.uuid_generator
        when :random
          UUIDTools::UUID.random_create
        when :time
          UUIDTools::UUID.timestamp_create
        end
      end
    end

    def generate_uuids_if_needed
      self.class.uuid_attributes.each do |attr|
        self.send("#{attr}=", create_uuid) unless self.send(attr)
      end
    end

  end
end
