require 'crosstest/psychic/version'
require 'crosstest/core'
require 'crosstest/psychic/error'
require 'yaml'

autoload :Thor, 'thor'

module Crosstest
  autoload :Shell,  'crosstest/shell'
  autoload :OutputHelper, 'crosstest/output_helper'
  class Psychic
    autoload :Tokens,   'crosstest/psychic/tokens'
    module Tokens
      autoload :RegexpTokenHandler,   'crosstest/psychic/tokens'
      autoload :MustacheTokenHandler,   'crosstest/psychic/tokens'
    end
    autoload :Hints, 'crosstest/psychic/hints'
    autoload :FileFinder, 'crosstest/psychic/file_finder'
    autoload :FactoryManager, 'crosstest/psychic/factory_manager'
    autoload :ScriptFactoryManager, 'crosstest/psychic/script_factory_manager'
    autoload :TaskFactoryManager, 'crosstest/psychic/task_factory_manager'
    autoload :MagicTaskFactory, 'crosstest/psychic/magic_task_factory'
    autoload :ScriptFactory, 'crosstest/psychic/script_factory'
    autoload :CommandTemplate, 'crosstest/psychic/command_template'
    autoload :Task, 'crosstest/psychic/task'
    autoload :Script, 'crosstest/psychic/script'
    autoload :ScriptFinder, 'crosstest/psychic/script_finder'
    autoload :ScriptRunner, 'crosstest/psychic/script_runner'
    autoload :TaskRunner, 'crosstest/psychic/task_runner'

    FactoryManager.autoload_factories!

    include Core::Logger
    include Shell
    include TaskRunner
    include ScriptRunner
    attr_reader :cwd, :env, :os, :hints, :parameters, :opts

    DEFAULT_PARAMS_FILE = 'psychic-parameters.yaml'

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
    end

    def execute(command, *args)
      # Crossdoc sends raw strings to execute...
      full_cmd = if command.respond_to? :render
                   command.render(*args)
                 else
                   [command, *args].join(' ')
                 end
      logger.info("Executing: #{full_cmd}")
      shell.execute(full_cmd, @shell_opts)
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
      hint_data = Crosstest::Core::Util.symbolized_hash(@opts[:hints] || load_hints || {})
      @hints = Hints.new hint_data
      @opts.merge! Crosstest::Core::Util.symbolized_hash(@hints.options)
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
