require "activeuuid/version"
require 'activeuuid/patches'
require 'activeuuid/uuid'
require 'activeuuid/schema_dumper'
require 'activeuuid/railtie' if defined?(Rails::Railtie)

module ActiveUUID
end

ActiveUUID::Patches.apply!
