require 'psychic/runner/version'
require 'thor'

autoload :YAML, 'yaml'

module Psychic
  autoload :Util,   'psychic/util'
  autoload :Logger, 'psychic/logger'
  autoload :Shell,  'psychic/shell'
  autoload :OutputHelper, 'psychic/output_helper'
  class Runner
    autoload :BaseRunner, 'psychic/runner/base_runner'
    autoload :CodeSample, 'psychic/runner/code_sample'
    autoload :SampleFinder, 'psychic/runner/sample_finder'
    autoload :SampleRunner, 'psychic/runner/sample_runner'
    autoload :HotRunner, 'psychic/runner/hot_runner'
    autoload :CompoundRunner, 'psychic/runner/compound_runner'
    autoload :ColdRunnerRegistry, 'psychic/runner/cold_runner_registry'
    class TaskNotImplementedError < NotImplementedError; end
    ColdRunnerRegistry.autoload_runners!

    include BaseRunner
    include SampleRunner
    attr_reader :runners, :hot_runner, :cold_runners

    def initialize(opts = { cwd: Dir.pwd })
      fail 'cwd is required' unless opts[:cwd]
      opts[:cwd] = Pathname(opts[:cwd]).to_s # must be a string on windows...
      super
      @hot_runner = HotRunner.new(opts)
      @sample_finder = SampleFinder.new(opts[:cwd], @hot_runner.hints['samples'])
      @cold_runners = ColdRunnerRegistry.active_runners(opts)
      @runners = [@hot_runner, @cold_runners].flatten
      @known_tasks = @runners.flat_map(&:known_tasks).uniq
    end

    def known_samples
      @sample_finder.known_samples
    end

    def [](task_name)
      runner = runners.find { |r| r.command_for_task(task_name) }
      return nil unless runner
      runner[task_name]
    end
  end
end
