require 'active_record'
require 'active_support/concern'


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

    module PostgreSQLJdbcColumn
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
          return :uuid if field_type == 'uuid'
          original_simplified_type(field_type)
        end

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
      ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition

      ActiveRecord::ConnectionAdapters::Column.send :include, Column
      ArJdbc::MySQL::Column.send :include, MysqlJdbcColumn if defined? ArJdbc::MySQL::Column
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.send :include, PostgreSQLColumn if defined? ActiveRecord::ConnectionAdapters::PostgreSQLColumn
      ArJdbc::PostgreSQL::Column.send :include, PostgreSQLJdbcColumn if defined? ArJdbc::MySQL::Column

      ActiveRecord::ConnectionAdapters::MysqlAdapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::MysqlAdapter
      ActiveRecord::ConnectionAdapters::Mysql2Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PostgreSQLQuoting if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    end
  end
end
