require 'activeuuid'
require 'rails'

module ActiveUUID
  class Railtie < Rails::Railtie
    railtie_name :activeuuid

    module Migrations
      def uuid(*args)
        options = args.extract_options!
        column_names = args
        column_names.each do |name|
          column(name, "binary(16)#{' primary key' if options.delete(:primary_key)}", options)
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

        alias_method_chain :quote, :visiting
      end
    end

    config.to_prepare do
      ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition
      ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::AbstractMysqlAdapter
      ActiveRecord::ConnectionAdapters::SQLite3Adapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::SQLite3Adapter
      ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.send :include, Quoting if defined? ActiveRecord::ConnectionAdapters::PostgreSQLAdapter
    end
  end
end
