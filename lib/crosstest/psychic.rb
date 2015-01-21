require 'crosstest/psychic/version'
require 'crosstest/core'
require 'crosstest/psychic/error'

autoload :Thor, 'thor'
autoload :YAML, 'yaml'

module Crosstest
  autoload :Shell,  'crosstest/shell'
  autoload :OutputHelper, 'crosstest/output_helper'
  class Psychic
    autoload :Tokens,   'crosstest/psychic/tokens'
    autoload :FileFinder, 'crosstest/psychic/file_finder'
    autoload :MagicTaskFactory, 'crosstest/psychic/magic_task_factory'
    autoload :BaseRunner, 'crosstest/psychic/base_runner'
    autoload :CommandTemplate, 'crosstest/psychic/command_template'
    autoload :Task, 'crosstest/psychic/task'
    autoload :CodeSample, 'crosstest/psychic/code_sample'
    autoload :SampleFinder, 'crosstest/psychic/sample_finder'
    autoload :SampleRunner, 'crosstest/psychic/sample_runner'
    autoload :HotReadTaskFactory, 'crosstest/psychic/hot_read_task_factory'
    autoload :TaskFactoryRegistry, 'crosstest/psychic/task_factory_registry'
    TaskFactoryRegistry.autoload_task_factories!

    include BaseRunner
    include SampleRunner
    attr_reader :runners, :hot_read_task_factory, :task_factories, :sample_factories, :os

    def initialize(opts = { cwd: Dir.pwd }) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      # TODO: Will reduce method length after further splitting Runner vs TaskFactory
      fail 'cwd is required' unless opts[:cwd]
      # must be a string on windows...
      opts[:cwd] = Pathname(opts[:cwd]).to_s
      @opts = opts
      init_attr(:cwd) { Dir.pwd }
      init_hints
      init_attr(:logger) { new_logger }
      init_attr(:env) { ENV.to_hash }
      init_attr(:os) { RbConfig::CONFIG['host_os'] }
      init_attrs :cli, :interactive, :parameter_mode, :restore_mode, :print
      @shell_opts = select_shell_opts
      @parameters = load_parameters(opts[:parameters])
      # super
      @hot_read_task_factory = HotReadTaskFactory.new(self, opts)
      @sample_finder = SampleFinder.new(opts[:cwd], @hot_read_task_factory.hints['samples'])
      @task_factories = TaskFactoryRegistry.activate_task_factories(self, opts)
      @runners = [@hot_read_task_factory, @task_factories].flatten
      @known_tasks = @runners.flat_map(&:known_tasks).uniq
    end

    def known_samples
      @sample_finder.known_samples
    end

    def command_for_task(task_name)
      runner = runners.find { |r| r.known_task?(task_name) }
      return nil unless runner
      CommandTemplate.new(runner.command_for_task(task_name))
    end

    def os_family
      case os
      when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
        :windows
      when /darwin|mac os/
        :macosx
      when /linux/
        :linux
      when /solaris|bsd/
        :unix
      else
        :unknown
      end
    end

    private

    def init_attr(var)
      var_name = "@#{var}"
      var_value = @opts[var]
      var_value = yield if var_value.nil? && block_given?
      instance_variable_set(var_name, var_value)
    end

    def init_attrs(*vars)
      vars.each do | var |
        init_attr var
      end
    end

    def init_hints
      @hints = Crosstest::Core::Util.stringified_hash(@opts[:hints] || load_hints || {})
      if @hints['options']
        @opts.merge! Crosstest::Core::Util.symbolized_hash(@hints['options'])
      end
    end

    def select_shell_opts
      # Make sure to delete any option that isn't a MixLib::ShellOut option
      @opts.select { |key, _| Crosstest::Shell::AVAILABLE_OPTIONS.include? key }
    end

    def load_hints
      hints_file = Dir.glob("#{@cwd}/psychic.{yaml,yml}", File::FNM_CASEFOLD).first
      YAML.load(File.read(hints_file)) unless hints_file.nil?
    end

    def load_parameters(parameters)
      if parameters.nil? || parameters.is_a?(String)
        load_parameters_file(parameters)
      else
        parameters
      end
    end

    def load_parameters_file(file = nil)
      if file.nil?
        file ||= File.expand_path(DEFAULT_PARAMS_FILE, cwd)
        return {} unless File.exist? file
      end
      parameters = Tokens.replace_tokens(File.read(file), @env)
      YAML.load(parameters)
    end
  end
end
