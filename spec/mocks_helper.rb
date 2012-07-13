
require 'rspec/mocks'
RSpec::Mocks::setup(self)

module Arel
  module Visitors
    class Visitor; end
    class ToSql; end
  end
end