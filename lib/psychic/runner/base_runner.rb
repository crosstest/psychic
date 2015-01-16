module Psychic
  class Runner
    module BaseRunner
      DEFAULT_PARAMS_FILE = 'psychic-parameters.yaml'
      TASK_PRIORITY = 5

      include Psychic::Shell
      include Psychic::Logger

      attr_reader :known_tasks, :tasks, :cwd, :env, :hints, :priority

      module ClassMethods
        def register_task_factory
          Psychic::Runner::TaskFactoryRegistry.register(self)
        end

        def magic_file_patterns
          @magic_file_patterns ||= []
        end

        def magic_file(pattern) # rubocop:disable Style/TrivialAccessors
          magic_file_patterns << pattern
        end

        def magic_env_vars
          @magic_env_vars ||= []
        end

        def magic_env_var(var)
          magic_env_vars << var
        end

        def known_tasks
          @known_tasks ||= []
        end

        def tasks
          @tasks ||= {}
        end

        def task(name, &block)
          name = name.to_s
          tasks[name] = block
          known_tasks << name
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def initialize(opts = {})
        @opts = opts
        @priority = TASK_PRIORITY
        init_attr(:cwd) { Dir.pwd }
        init_hints
        init_attr(:known_tasks) { self.class.known_tasks }
        init_attr(:tasks) { self.class.tasks }
        init_attr(:logger) { new_logger }
        init_attr(:env) { ENV.to_hash }
        init_attrs :cli, :interactive, :parameter_mode, :restore_mode, :print
        @shell_opts = select_shell_opts
        @parameters = load_parameters(opts[:parameters])
      end

      def known_task?(task_name)
        known_tasks.include?(task_name.to_s)
      end

      def task_for(task_name)
        tasks[task_name] if tasks.include? task_name
      end

      def execute(command, *args)
        full_cmd = [command, *args].join(' ')
        logger.info("Executing: #{full_cmd}")
        shell.execute(full_cmd, @shell_opts) unless print?
      end

      def find_task(task_name, *_args)
        task_name = task_name.to_s
        command = task_for(task_name)
        command = command.call if command.respond_to? :call
        fail Psychic::Runner::TaskNotImplementedError, task_name if command.nil?
        Task.new(task_name, command, TASK_PRIORITY)
      end

      def execute_task(task_name, *args)
        task = find_task(task_name, *args)
        execute(task.command, *args)
      end

      def print?
        @print == true
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
        @hints = Psychic::Util.stringified_hash(@opts[:hints] || load_hints || {})
        if @hints['options']
          @opts.merge! Psychic::Util.symbolized_hash(@hints['options'])
        end
      end

      def select_shell_opts
        # Make sure to delete any option that isn't a MixLib::ShellOut option
        @opts.select { |key, _| Psychic::Shell::AVAILABLE_OPTIONS.include? key }
      end

      def load_hints
        hints_file = Dir["#{@cwd}/psychic.{yaml,yml}"].first
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
        parameters = Psychic::Util.replace_tokens(File.read(file), @env)
        YAML.load(parameters)
      end

      # Blame Ruby's flatten and Array(...) behavior...
      def to_ary
        nil
      end
      alias_method :to_a, :to_ary
    end
  end
end
