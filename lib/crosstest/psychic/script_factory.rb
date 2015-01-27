module Crosstest
  class Psychic
    class ScriptFactory < FactoryManager
      include Crosstest::Core::Logger

      TASK_PRIORITY = 5

      attr_reader :priority, :task_runner, :extensions

      class << self
        def register_script_factory
          Crosstest::Psychic::ScriptFactoryManager.register_factory(self)
        end

        def extensions
          @extensions ||= {}
        end

        def runs_extension(ext, priority = 5)
          extensions[ext] = priority
        end

        def priority_for_extension(ext)
          extensions[ext] || extensions[ext.gsub('.', '')]
        end
      end

      def initialize(task_runner, opts)
        @task_runner = task_runner
        @opts = opts
        @logger = opts[:logger] || new_logger
      end

      def active?
        true
      end

      def can_run_extension?(ext)
        self.class.extensions.include? ext
      end

      def can_run_sample?(code_sample)
        extname = task_runner.CodeSample(code_sample).extname
        self.class.priority_for_extension(extname)
      end

      def command_for_sample(code_sample)
        raise NotImplementedError, 'This should be implemented by subclasses'
      end
    end
  end
end
