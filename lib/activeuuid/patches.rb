module ActiveUUID
  module Patches
    module Migrations
      def uuid(*column_names)
        options = column_names.extract_options!
        column_names.each do |name|
          type = @base.adapter_name.downcase == 'postgresql' ? 'uuid' : 'binary(16)'
          column(name, "#{type}#{' PRIMARY KEY' if options.delete(:primary_key)}", options)
        end
      end
    end

    module Column
      extend ActiveSupport::Concern

      included do
        def uuid?
          sql_type == 'binary(16)'
        end

        def type_cast_with_uuid(value)
          if uuid?
            UUIDTools::UUID.serialize(value)
          else
            type_cast_without_uuid(value)
          end
        end

        def type_cast_code_with_uuid(var_name)
          if uuid?
            "UUIDTools::UUID.serialize(#{var_name})"
          else
            type_cast_code_without_uuid(var_name)
          end
        end

        alias_method_chain :type_cast, :uuid
        alias_method_chain :type_cast_code, :uuid
      end
    end

    module PostgreSQLColumn
      extend ActiveSupport::Concern

      included do
        def uuid?
          sql_type == 'uuid'
        end
      end
    end

    module Quoting
      extend ActiveSupport::Concern

      included do
        def quote_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.uuid?
          quote_without_visiting(value, column)
        end

        def type_cast_with_visiting(value, column = nil)
          value = UUIDTools::UUID.serialize(value) if column && column.uuid?
          type_cast_without_visiting(value, column)
        end

        alias_method_chain :quote, :visiting
        alias_method_chain :type_cast, :visiting
      end
    end

    module PostgreSQLQuoting
      extend ActiveSupport::Concern

      included do
        def quote_with_visiting(value, column = nil)
          if column && column.uuid?
            value = UUIDTools::UUID.serialize(value)
            value = value.to_s if value.is_a? UUIDTools::UUID
          end
          quote_without_visiting(value, column)
        end

        def type_cast_with_visiting(value, column = nil)
          if column && column.uuid?
            value = UUIDTools::UUID.serialize(value)
            value = value.to_s if value.is_a? UUIDTools::UUID
          end
          type_cast_without_visiting(value, column)
        end

        alias_method_chain :quote, :visiting
        alias_method_chain :type_cast, :visiting
      end
    end

    def self.apply!
      ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition

      ActiveRecord::ConnectionAdapters::Column.send :include, Column
      ActiveRecord::ConnectionAdapters::PostgreSQLColumn.send :include, PostgreSQLColumn if defined? ActiveRecord::ConnectionAdapters::PostgreSQLColumn

      ActiveRecord::ConnectionAdapters::Mysql2Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PostgreSQLQuoting if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    end
  end
end
