require "activeuuid/version"

module ActiveUUID
  require 'lib/activeuuid/railtie' if defined?(Rails)
  require 'lib/activeuuid/uuid'
end
