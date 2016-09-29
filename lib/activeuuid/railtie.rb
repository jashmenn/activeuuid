require 'activeuuid'
require 'rails'

module ActiveUUID
  class Railtie < Rails::Railtie
    railtie_name :activeuuid
    initializer 'activeuuid.active_record' do
      #Ensure ConnectionAdapters are loaded before patching
      ActiveSupport.on_load :active_record do
        ActiveUUID::Patches.apply!
      end
    end
  end
end
