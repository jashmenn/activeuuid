require 'activeuuid'

module ActiveUUID::SpecSupport
  class SpecForAdapter
    def initialize
      @specs = {}
    end

    [:sqlite3, :mysql2, :postgresql].each do |name|
      send :define_method, name do |&block|
        @specs[name] = block
      end
    end

    def run(connection)
      name = connection.adapter_name.downcase.to_sym
      @specs[name].call() if(@specs.include? name)
    end
  end
end