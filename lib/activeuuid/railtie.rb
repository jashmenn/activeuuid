require 'activeuuid'
require 'rails'

module ActiveUUID
  class Railtie < Rails::Railtie
    railtie_name :activeuuid

    config.to_prepare do
      ActiveUUID::Patches.apply!
    end
  end
end
