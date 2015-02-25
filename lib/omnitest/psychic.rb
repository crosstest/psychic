require 'omnitest/core'
require 'omnitest/psychic/version'
require 'omnitest/psychic/error'
require 'omnitest/psychic/code2doc'
require 'yaml'

autoload :Thor, 'thor'

module Omnitest
  autoload :Shell,  'omnitest/shell'
  autoload :OutputHelper, 'omnitest/output_helper'

  # The primary interface for using Psychic as an API.
  #
  # Detects scripts and tools that can run tasks in the instance's working directory,
  # so that Psychic can act as a universal task/script selection and execution system.
  class Psychic # rubocop:disable Metrics/ClassLength
    autoload :Tokens,   'omnitest/psychic/tokens'
    module Tokens
      autoload :RegexpTokenHandler,   'omnitest/psychic/tokens'
      autoload :MustacheTokenHandler,   'omnitest/psychic/tokens'
    end
    module Execution
      autoload :DefaultStrategy, 'omnitest/psychic/execution/default_strategy'
      autoload :TokenStrategy, 'omnitest/psychic/execution/token_strategy'
      autoload :EnvStrategy, 'omnitest/psychic/execution/env_strategy'
      autoload :FlagStrategy, 'omnitest/psychic/execution/flag_strategy'
    end
    autoload :Hints, 'omnitest/psychic/hints'
    autoload :FileFinder, 'omnitest/psychic/file_finder'
    autoload :FactoryManager, 'omnitest/psychic/factory_manager'
    autoload :ScriptFactoryManager, 'omnitest/psychic/script_factory_manager'
    autoload :ScriptFactoryManager, 'omnitest/psychic/script_factory_manager'
    autoload :TaskFactoryManager, 'omnitest/psychic/task_factory_manager'
    autoload :MagicTaskFactory, 'omnitest/psychic/magic_task_factory'
    autoload :ScriptFactory, 'omnitest/psychic/script_factory'
    autoload :CommandTemplate, 'omnitest/psychic/command_template'
    autoload :Task, 'omnitest/psychic/task'
    autoload :Script, 'omnitest/psychic/script'
    autoload :Workflow, 'omnitest/psychic/workflow'
    autoload :TaskRunner, 'omnitest/psychic/task_runner'
    autoload :ScriptRunner, 'omnitest/psychic/script_runner'

    FactoryManager.autoload_factories!

    include Core::Logger
    include Shell
    include TaskRunner
    include ScriptRunner

    # @return [String] A name for logging and reporting.
    # The default value is the name of the current working directory.
    attr_reader :name
    # @return [Dir] Current working directory for running commands.
    attr_reader :cwd
    alias_method :basedir, :cwd
    # @return [Hash] Environment variables to use when executing commands.
    #   The default is to pass all environment variables to the command.
    attr_reader :env
    # @return [String] The Operating System to target. Autodetected if unset.
    attr_reader :os
    # @return [Hints] Psychic "hints" that are used to help Psychic locate tasks or scripts.
    attr_reader :hints
    # @return [Hash] Parameters to use as input for scripts.
    attr_reader :parameters
    # @return [Hash] Additional options
    attr_reader :opts

    DEFAULT_PARAMS_FILE = 'psychic-parameters.yaml'

    # Creates a new Psychic instance that can be used to execute tasks and scripts.
    # All options are
    # @params [Hash] opts
    # @option opts [Dir] :cwd sets the current working directory
    # @option opts [Logger] :logger assigns a logger
    # @option opts [Hash] :env sets environment variables
    # @option opts [String] :name a name for logging and reporting
    # @option opts [String] :os the target operating system
    # @option opts [String] :interactive run psychic in interactive mode, where it will prompt for input
    def initialize(opts = { cwd: Dir.pwd  }) # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
      opts[:cwd] ||= Dir.pwd
      # must be a string on windows...
      @cwd = opts[:cwd] = Pathname(opts[:cwd]).to_s
      @opts = opts
      init_attr(:name) { File.basename cwd }
      init_hints
      init_attr(:logger) { new_logger }
      init_attr(:env) { ENV.to_hash }
      init_attr(:os) { RbConfig::CONFIG['host_os'] }
      init_attrs :cli, :interactive, :parameter_mode, :restore_mode, :print
      @shell_opts = select_shell_opts
      @parameters = load_parameters(opts[:parameters])
    end

    # Executes a command using the options set on this Psychic instance.
    #   @param [String] command the command to execute
    #   @param [*args] *args additional arguments to join to the command
    #   @return [ExecutionResult] the result of running the command
    #   @raises [ExecutionError] if the command
    #
    # @example
    #   psychic.execute('echo', 'hello', 'world')
    #   #<Omnitest::Shell::ExecutionResult:0x007fdfe15208f0 @command="echo hello world",
    #     @exitstatus=0, @stderr="", @stdout="hello world\n">
    #
    # @example
    #   psychic.execute('foo')
    #   # Omnitest::Shell::ExecutionError: No such file or directory - foo
    def execute(command, *args)
      shell_opts = @shell_opts.dup
      shell_opts.merge!(args.shift) if args.first.is_a? Hash
      full_cmd = [command, *args].join(' ')
      logger.banner("Executing: #{full_cmd}")
      shell.execute(full_cmd, shell_opts)
    end

    def workflow(name = 'workflow', options = {}, &block)
      Workflow.new(self, name, options, &block)
    end

    # Detects the Operating System family for the selected Operating System.
    # @return [Symbol] The operating system family for {#os}.
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

    # @return [Boolean] true if Psychic is in interactive mode and will prompt for decisions
    def interactive?
      @opts[:interactive]
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
      hint_data = Omnitest::Core::Util.symbolized_hash(@opts[:hints] || load_hints || {})
      @hints = Hints.new hint_data
      @opts.merge! Omnitest::Core::Util.symbolized_hash(@hints.options)
    end

    def select_shell_opts
      # Make sure to delete any option that isn't a MixLib::ShellOut option
      @opts.select { |key, _| Omnitest::Shell::AVAILABLE_OPTIONS.include? key }
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
      # Just return it as a template, not as YAML
      File.read(file)
    end
  end
end
