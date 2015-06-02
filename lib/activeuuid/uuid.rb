require 'uuidtools'

# monkey-patch Friendly::UUID to serialize UUIDs
module UUIDTools
  class UUID
    alias_method :id, :raw

    # duck typing activerecord 3.1 dirty hack )
    def gsub *; self; end

    def ==(another_uuid)
      self.to_s == another_uuid.to_s
    end

    def next
      self.class.random_create
    end

    def quoted_id
      s = raw.unpack("H*")[0]
      "x'#{s}'"
    end

    def as_json(options = nil)
      to_s
    end

    def to_param
      to_s
    end

    def self.serialize(value)
      case value
      when self
        value
      when String
        parse_string value
      else
        nil
      end
    end

    def bytesize
      16
    end

  private

    def self.parse_string(str)
      return nil if str.length == 0
      if str.length == 36
        parse str
      elsif str.length == 32
        parse_hexdigest str
      else
        parse_raw str
      end
    end
  end
end

module Arel
  module Visitors
    class DepthFirst < Arel::Visitors::Visitor
      def visit_UUIDTools_UUID(o, a = nil)
        o.quoted_id
      end
    end

    class MySQL < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o, a = nil)
        o.quoted_id
      end
    end

    class SQLite < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o, a = nil)
        o.quoted_id
      end
    end

    class PostgreSQL < Arel::Visitors::ToSql
      def visit_UUIDTools_UUID(o, a = nil)
        "'#{o.to_s}'"
      end
    end
  end
end

module ActiveUUID
  module UUID
    extend ActiveSupport::Concern

    included do
      class_attribute :_natural_key, instance_writer: false
      class_attribute :_uuid_namespace, instance_writer: false
      class_attribute :_uuid_generator, instance_writer: false
      self._uuid_generator = :random

      singleton_class.alias_method_chain :instantiate, :uuid
      before_create :generate_uuids_if_needed
    end

    module ClassMethods
      def natural_key(*attributes)
        self._natural_key = attributes
      end

      def uuid_namespace(namespace)
        namespace = UUIDTools::UUID.parse_string(namespace) unless namespace.is_a? UUIDTools::UUID
        self._uuid_namespace = namespace
      end

      def uuid_generator(generator_name)
        self._uuid_generator = generator_name
      end

      def uuids(*attributes)
        ActiveSupport::Deprecation.warn <<-EOS
          ActiveUUID detects uuid columns independently.
          There is no more need to use uuid method.
        EOS
      end

      def instantiate_with_uuid(record, record_models = nil)
        uuid_columns.each do |uuid_column|
          record[uuid_column] = UUIDTools::UUID.serialize(record[uuid_column]).to_s if record[uuid_column]
        end
        instantiate_without_uuid(record)
      end

      def uuid_columns
        @uuid_columns ||= columns.select { |c| c.type == :uuid }.map(&:name)
      end
    end

    def create_uuid
      if _natural_key
        # TODO if all the attributes return nil you might want to warn about this
        chained = _natural_key.map { |attribute| self.send(attribute) }.join('-')
        UUIDTools::UUID.sha1_create(_uuid_namespace || UUIDTools::UUID_OID_NAMESPACE, chained)
      else
        case _uuid_generator
        when :random
          UUIDTools::UUID.random_create
        when :time
          UUIDTools::UUID.timestamp_create
        end
      end
    end

    def generate_uuids_if_needed
      primary_key = self.class.primary_key
      if self.class.columns_hash[primary_key].type == :uuid
        send("#{primary_key}=", create_uuid) unless send("#{primary_key}?")
      end
    end

  end
end
