require 'active_record'
require 'active_support/concern'

if (ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR == 2) ||
  (ActiveRecord::VERSION::MAJOR == 5 && ActiveRecord::VERSION::MINOR == 0)
  module ActiveRecord
    module Type
      class UUID < Binary # :nodoc:
        def type
          :uuid
        end

        def serialize(value)
          return if value.nil?
          UUIDTools::UUID.serialize(value)
        end

        def cast_value(value)
          UUIDTools::UUID.serialize(value)
        end
      end
    end
  end

  module ActiveRecord
    module ConnectionAdapters
      module PostgreSQL
        module OID # :nodoc:
          class Uuid < Type::Value # :nodoc:
            def type_cast_from_user(value)
              UUIDTools::UUID.serialize(value) if value
            end
          end
        end
      end
    end
  end
end

module ActiveUUID
  module Patches
    module Migrations
      def uuid(*column_names)
        options = column_names.extract_options!
        column_names.each do |name|
          type = ActiveRecord::Base.connection.adapter_name.downcase == 'postgresql' ? 'uuid' : 'binary(16)'
          column(name, "#{type}#{' PRIMARY KEY' if options.delete(:primary_key)}", options)
        end
      end
    end

    module Column
      extend ActiveSupport::Concern

      def self.prepended(klass)
        def type_cast_with_uuid(value)
          return UUIDTools::UUID.serialize(value) if type == :uuid
          super
        end

        def type_cast_code_with_uuid(var_name)
          return "UUIDTools::UUID.serialize(#{var_name})" if type == :uuid
          super
        end

        def simplified_type_with_uuid(field_type)
          return :uuid if field_type == 'binary(16)' || field_type == 'binary(16,0)'
          super
        end
      end
    end

    module MysqlJdbcColumn
      extend ActiveSupport::Concern

      included do
        # This is a really hacky solution, but it's the only way to support the
        # MySql JDBC adapter without breaking backwards compatibility.
        # It would be a lot easier if AR had support for custom defined types.
        #
        # Here's the path of execution:
        # (1) JdbcColumn calls ActiveRecord::ConnectionAdapters::Column super constructor
        # (2) super constructor calls simplified_type from MysqlJdbcColumn, since it's redefined here
        # (3) if it's not a uuid, it calls original_simplified_type from ArJdbc::MySQL::Column module
        # (4)   if there's no match ArJdbc::MySQL::Column calls super (ActiveUUID::Column.simplified_type_with_uuid)
        # (5)     Since it's no a uuid (see step 3), simplified_type_without_uuid is called,
        #         which maps to AR::ConnectionAdapters::Column.simplified_type (which has no super call, so we're good)
        #
        alias_method :original_simplified_type, :simplified_type

        def simplified_type(field_type)
          return :uuid if field_type == 'binary(16)' || field_type == 'binary(16,0)'
          original_simplified_type(field_type)
        end
      end
    end


    module PostgreSQLColumn
      extend ActiveSupport::Concern

      def self.prepended(klass)
        def type_cast_with_uuid(value)
          return UUIDTools::UUID.serialize(value) if type == :uuid
          super
        end
        alias_method_chain :type_cast, :uuid if ActiveRecord::VERSION::MAJOR >= 4

        def simplified_type_with_pguuid(field_type)
          return :uuid if field_type == 'uuid'
          super
        end
      end
    end

    module Quoting
      extend ActiveSupport::Concern

      def self.prepended(klass)
        def quote_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          super
        end

        def type_cast_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          super
        end

        def native_database_types_with_uuid
          @native_database_types ||= native_database_types_without_uuid.merge(uuid: { name: 'binary', limit: 16 })
        end
      end
    end

    module PostgreSQLQuoting
      extend ActiveSupport::Concern

      def self.prepended(klass)
        def quote_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          value = value.to_s if value.is_a? UUIDTools::UUID
          super
        end

        def type_cast_with_visiting(value, column = nil, *args)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          value = value.to_s if value.is_a? UUIDTools::UUID
          super
        end

        def native_database_types_with_pguuid
          @native_database_types ||= native_database_types_without_pguuid.merge(uuid: { name: 'uuid' })
        end
      end
    end

    module PostgresqlTypeOverride
      def deserialize(value)
        UUIDTools::UUID.serialize(value) if value
      end

      alias_method :cast, :deserialize
    end

    module TypeMapOverride
      def initialize_type_map(m)
        super

        register_class_with_limit m, /binary\(16(,0)?\)/i, ::ActiveRecord::Type::UUID
      end
    end

    module MysqlTypeToSqlOverride
      def type_to_sql(type, limit = nil, precision = nil, scale = nil, unsigned = nil)
        type.to_s == 'uuid' ? 'binary(16)' : super
      end
    end

    module ConnectionHandling
      def establish_connection(_ = nil)
        super

        ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
        ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition

        if ActiveRecord::VERSION::MAJOR == 5 && ActiveRecord::VERSION::MINOR == 0
          if defined? ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
            ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend TypeMapOverride
            ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.prepend MysqlTypeToSqlOverride
          end

          ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend TypeMapOverride if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
          ActiveRecord::ConnectionAdapters::PostgreSQL::OID::Uuid.prepend PostgresqlTypeOverride if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
        elsif ActiveRecord::VERSION::MAJOR == 4 && ActiveRecord::VERSION::MINOR == 2
          ActiveRecord::ConnectionAdapters::Mysql2Adapter.prepend TypeMapOverride if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
          ActiveRecord::ConnectionAdapters::SQLite3Adapter.prepend TypeMapOverride if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
        else
          ActiveRecord::ConnectionAdapters::Column.send :include, Column
          ActiveRecord::ConnectionAdapters::PostgreSQLColumn.send :include, PostgreSQLColumn if defined? ActiveRecord::ConnectionAdapters::PostgreSQLColumn
        end

        ActiveRecord::ConnectionAdapters::MysqlAdapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
        ActiveRecord::ConnectionAdapters::Mysql2Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
        ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
        ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PostgreSQLQuoting if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
      end
    end

    def self.apply!
      ActiveRecord::Base.singleton_class.prepend ConnectionHandling
    end
  end
end