require 'active_record'
require 'active_support/concern'

if ActiveRecord::VERSION::MAJOR == 4 and ActiveRecord::VERSION::MINOR == 2
  module ActiveRecord
    module Type
      class UUID < Binary # :nodoc:
        def type
          :uuid
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
            alias_method :type_cast_from_database, :type_cast_from_user
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

      included do
        def type_cast_with_uuid(value)
          return UUIDTools::UUID.serialize(value) if type == :uuid
          type_cast_without_uuid(value)
        end

        def type_cast_code_with_uuid(var_name)
          return "UUIDTools::UUID.serialize(#{var_name})" if type == :uuid
          type_cast_code_without_uuid(var_name)
        end

        def simplified_type_with_uuid(field_type)
          return :uuid if field_type == 'binary(16)' || field_type == 'binary(16,0)'
          simplified_type_without_uuid(field_type)
        end

        alias_method_chain :type_cast, :uuid
        alias_method_chain :type_cast_code, :uuid if ActiveRecord::VERSION::MAJOR < 4
        alias_method_chain :simplified_type, :uuid
      end
    end

    module PostgreSQLColumn
      extend ActiveSupport::Concern

      included do
        def type_cast_with_uuid(value)
          return UUIDTools::UUID.serialize(value) if type == :uuid
          type_cast_without_uuid(value)
        end
        alias_method_chain :type_cast, :uuid if ActiveRecord::VERSION::MAJOR >= 4

        def simplified_type_with_pguuid(field_type)
          return :uuid if field_type == 'uuid'
          simplified_type_without_pguuid(field_type)
        end

        alias_method_chain :simplified_type, :pguuid
      end
    end

    module Quoting
      extend ActiveSupport::Concern

      included do
        def quote_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          quote_without_visiting(value, column)
        end

        def type_cast_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          type_cast_without_visiting(value, column)
        end

        def native_database_types_with_uuid
          @native_database_types ||= native_database_types_without_uuid.merge(uuid: { name: 'binary', limit: 16 })
        end

        alias_method_chain :quote, :visiting
        alias_method_chain :type_cast, :visiting
        alias_method_chain :native_database_types, :uuid
      end
    end

    module PostgreSQLQuoting
      extend ActiveSupport::Concern

      included do
        def quote_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          value = value.to_s if value.is_a? UUIDTools::UUID
          quote_without_visiting(value, column)
        end

        def type_cast_with_visiting(value, column = nil, *args)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          value = value.to_s if value.is_a? UUIDTools::UUID
          type_cast_without_visiting(value, column, *args)
        end

        def native_database_types_with_pguuid
          @native_database_types ||= native_database_types_without_pguuid.merge(uuid: { name: 'uuid' })
        end

        alias_method_chain :quote, :visiting
        alias_method_chain :type_cast, :visiting
        alias_method_chain :native_database_types, :pguuid
      end
    end

    module AbstractAdapter
      extend ActiveSupport::Concern

      included do
        def initialize_type_map_with_uuid(m)
          initialize_type_map_without_uuid(m)
          register_class_with_limit m, /binary\(16(,0)?\)/i, ::ActiveRecord::Type::UUID
        end

        alias_method_chain :initialize_type_map, :uuid
      end
    end

    def self.apply!
      ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition

      if ActiveRecord::VERSION::MAJOR == 4 and ActiveRecord::VERSION::MINOR == 2
        ActiveRecord::ConnectionAdapters::Mysql2Adapter.send :include, AbstractAdapter if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
        ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, AbstractAdapter if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      else
        ActiveRecord::ConnectionAdapters::Column.send :include, Column
        ActiveRecord::ConnectionAdapters::PostgreSQLColumn.send :include, PostgreSQLColumn if defined? ActiveRecord::ConnectionAdapters::PostgreSQLColumn
      end

      ActiveRecord::ConnectionAdapters::Mysql2Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PostgreSQLQuoting if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    end
  end
end
