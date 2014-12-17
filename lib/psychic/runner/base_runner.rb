module Psychic
  class Runner
    module BaseRunner
      DEFAULT_PARAMS_FILE = 'psychic-parameters.yaml'

      include Psychic::Shell
      include Psychic::Logger

      attr_reader :known_tasks
      attr_reader :cwd
      attr_reader :env
      attr_reader :hints

      module ClassMethods
        attr_accessor :magic_file_pattern

        def register_runner
          Psychic::Runner::ColdRunnerRegistry.register(self)
        end

        def magic_file(pattern) # rubocop:disable Style/TrivialAccessors
          @magic_file_pattern = pattern
        end
      end

      def self.included(base)
        base.extend(ClassMethods)
      end

      def initialize(opts = {}, _hints = {})
        @cwd = opts[:cwd] ||= Dir.pwd
        @hints = Psychic::Util.stringified_hash(opts[:hints] || load_hints || {})
        if @hints['options']
          opts.merge! Psychic::Util.symbolized_hash(@hints['options'])
        end
        @logger = opts[:logger] || new_logger
        @env = opts[:env] || ENV.to_hash
        @parameters = load_parameters(opts[:parameters])
        @cli, @interactive_mode = opts[:cli], opts[:interactive]
        @parameter_mode, @restore_mode, @dry_run = opts[:parameter_mode], opts[:restore_mode], opts[:dry_run]
        # Make sure to delete any option that isn't a MixLib::ShellOut option
        @shell_opts = opts.select { |key, _| Psychic::Shell::AVAILABLE_OPTIONS.include? key }
      end

      def respond_to_missing?(task, include_all = false)
        return true if known_tasks.include?(task.to_s)
        super
      end

      def method_missing(task, *args, &block)
        execute_task(task, *args)
      rescue Psychic::Runner::TaskNotImplementedError
        super
      end

      # Reserved words

      def execute(command, *args)
        full_cmd = [command, *args].join(' ')
        logger.info("Executing #{full_cmd}")
        shell.execute(full_cmd, @shell_opts) unless dry_run?
      end

      def command_for_task(task, *_args)
        task_name = task.to_s
        self[task_name]
      end

      def execute_task(task, *args)
        command = command_for_task(task, *args)
        fail Psychic::Runner::TaskNotImplementedError if command.nil?
        execute(command, *args)
      end

      def active?
        self.class.magic_file_pattern ? false : Dir["#{@cwd}/#{self.class.magic_file_pattern}"]
      end

      def dry_run?
        @dry_run == true
      end

      private

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
    end
  end
end
