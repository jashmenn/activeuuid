module ActiveUUID
  module Patches
    module Migrations
      def uuid(*args)
        options = args.extract_options!
        column_names = args
        column_names.each do |name|
          type = @base.adapter_name.downcase == 'postgresql' ? 'uuid' : 'binary(16)'
          column(name, "#{type}#{' PRIMARY KEY' if options.delete(:primary_key)}", options)
        end
      end
    end

    module Quoting
      extend ActiveSupport::Concern

      included do
        def quote_with_visiting(value, column = nil)
          value = ActiveUUID::UUIDSerializer.new.load(value) if column && column.sql_type == 'binary(16)'
          quote_without_visiting(value, column)
        end

        def type_cast_with_visiting(value, column = nil)
          value = ActiveUUID::UUIDSerializer.new.load(value) if column && column.sql_type == 'binary(16)'
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
          value = ActiveUUID::UUIDSerializer.new.load(value).to_s if column && column.sql_type == 'uuid'
          quote_without_visiting(value, column)
        end

        def type_cast_with_visiting(value, column = nil)
          value = ActiveUUID::UUIDSerializer.new.load(value).to_s if column && column.sql_type == 'uuid'
          type_cast_without_visiting(value, column)
        end

        alias_method_chain :quote, :visiting
        alias_method_chain :type_cast, :visiting
      end
    end

    def self.apply!
      ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition
      ActiveRecord::ConnectionAdapters::Mysql2Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::Mysql2Adapter
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, PostgreSQLQuoting if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    end
  end
end
