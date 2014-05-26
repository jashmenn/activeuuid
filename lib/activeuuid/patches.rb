require 'active_record'
require 'active_support/concern'


module ActiveUUID
  module Patches
    module Migrations
      def uuid(*column_names)
        options = column_names.extract_options!
        column_names.each do |name|
          type = case ActiveRecord::Base.connection.adapter_name.downcase
            when 'postgresql' then 'uuid'
            when 'sqlserver' then 'uniqueidentifier'
            else 'binary(16)'
          end
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
        alias_method_chain :simplified_type, :uuid
      end
    end

    module PostgreSQLColumn
      extend ActiveSupport::Concern

      included do
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

        def type_cast_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.type == :uuid
          value = value.to_s if value.is_a? UUIDTools::UUID
          type_cast_without_visiting(value, column)
        end

        def native_database_types_with_pguuid
          @native_database_types ||= native_database_types_without_pguuid.merge(uuid: { name: 'uuid' })
        end

        alias_method_chain :quote, :visiting
        alias_method_chain :type_cast, :visiting
        alias_method_chain :native_database_types, :pguuid
      end
    end

    def self.apply!
      is_pg = defined? ActiveRecord::ConnectionAdapters::PostgreSQLColumn
      has_uuid_type = is_pg and Rails.version[0].to_i >= 4

      ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition

      ActiveRecord::ConnectionAdapters::Column.send :include, Column unless has_uuid_type
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.send :include, PostgreSQLColumn if is_pg and !has_uuid_type

      ActiveRecord::ConnectionAdapters::Mysql2Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PostgreSQLQuoting if is_pg and !has_uuid_type
    end
  end
end
