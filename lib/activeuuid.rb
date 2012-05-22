require "activeuuid/version"

module ActiveUUID
  require 'activeuuid/railtie' if defined?(Rails::Railtie)
  require 'activeuuid/uuid'
end
