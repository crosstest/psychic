module Psychic
  class Runner
    module BaseRunner
      include Psychic::Shell
      include Psychic::Logger

      attr_reader :known_tasks
      attr_reader :cwd

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

      def initialize(opts = {})
        opts[:cwd] ||= Dir.pwd
        @logger = opts[:logger] || new_logger
        @cwd = opts[:cwd]
        @opts = opts
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
        shell.execute(full_cmd, @opts)
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
    end
  end
end
