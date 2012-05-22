require 'activeuuid'
require 'rails'

module ActiveUUID
  class Railtie < Rails::Railtie
    railtie_name :activeuuid
    initializer "activeuuid.configure_rails_initialization" do
      module ActiveRecord::ConnectionAdapters
        class Table
          def uuid (*args)
            options = args.extract_options!
            column_names = args
            column_names.each { |name| column(name, 'binary(16)', options) }
          end                                                                     
        end
      end

    end
  end
end
