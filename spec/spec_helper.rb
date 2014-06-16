require 'rubygems'
require 'bundler/setup'

Bundler.require :development

require 'active_record'
require 'active_support/all'

ActiveRecord::Base.logger = Logger.new(File.dirname(__FILE__) + "/debug.log")
ActiveRecord::Base.configurations = YAML::load(File.read(File.dirname(__FILE__) + "/support/database.yml"))
ActiveRecord::Base.establish_connection((ENV["DB"] || "sqlite3").to_sym)

require 'activeuuid'

ActiveRecord::Migrator.migrate(File.dirname(__FILE__) + "/support/migrate")
ActiveRecord::SchemaDumper.dump(ActiveRecord::Base.connection, STDOUT)

Dir["#{File.dirname(__FILE__)}/support/**/*.rb"].each { |f| require f }
Dir["#{File.dirname(__FILE__)}/fabricators/**/*.rb"].each { |f| require f }

RSpec.configure do |config|
  # Remove this line if you don't want RSpec's should and should_not
  # methods or matchers
  require 'rspec/expectations'
  config.include RSpec::Matchers

  # == Mock Framework
  config.mock_with :rspec

  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    DatabaseCleaner.clean
  end

  def spec_for_adapter(&block)
    switcher = ActiveUUID::SpecSupport::SpecForAdapter.new()
    yield switcher
    switcher.run(connection)
  end
end
