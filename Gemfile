source "http://rubygems.org"

# Specify your gem's dependencies in activeuuid.gemspec
gemspec

case version = ENV['ACTIVERECORD_VERSION'] || '~> 3.2'
when /master/
  gem "activerecord", :github => "rails/rails"
when /3-1-stable/
  gem "activerecord", :github => "rails/rails", :branch => "3-1-stable"
when /3-2-stable/
  gem "activerecord", :github => "rails/rails", :branch => "3-2-stable"
else
  gem "activerecord", version
end
