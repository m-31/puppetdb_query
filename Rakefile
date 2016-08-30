require 'rake'

require "rubocop/rake_task"
require 'rspec/core/rake_task'

desc "Run RuboCop on the lib directory"
RuboCop::RakeTask.new(:rubocop) do |task|
  task.formatters = ["fuubar"]
  task.options = ["-D"]
  task.fail_on_error = true
end

RSpec::Core::RakeTask.new(:spec) do |t|
  t.pattern = 'spec/**/*_spec.rb'
end

task :default => ["spec", "rubocop"]

