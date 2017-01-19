require "bundler/gem_tasks"

require 'rspec/core'
require 'rspec/core/rake_task'

module TempFixForRakeLastComment
  def last_comment
    last_description
  end 
end
Rake::Application.send :include, TempFixForRakeLastComment

RSpec::Core::RakeTask.new(:spec)

task :default => :spec
