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

    initializer "activeuuid.configure_rails_initialization" do
      ActiveRecord::ConnectionAdapters::Table.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::Table
      ActiveRecord::ConnectionAdapters::TableDefinition.send :include, Migrations if defined? ActiveRecord::ConnectionAdapters::TableDefinition
    end
  end
end
