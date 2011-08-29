require "activeuuid/version"

module ActiveUUID
  require 'activeuuid/railtie' if defined?(Rails)
  require 'activeuuid/uuid'
end
