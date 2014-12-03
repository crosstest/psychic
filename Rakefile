require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rake/notes/rake_task'
require 'rspec/core/rake_task'

task default: [:spec, :rubocop, :notes]

RSpec::Core::RakeTask.new('spec')
RuboCop::RakeTask.new(:rubocop) do |task|
  # abort rake on failure
  task.fail_on_error = true
end
