module Crosstest
  class Psychic
    class HotReadTaskFactory
      include BaseRunner
      def initialize(opts = {})
        super
        @tasks = hints['tasks'] || {}
        @known_tasks = @tasks.keys
      end

      def active?
        !@tasks.empty?
      end

      def command_for_task(task_name)
        return @tasks[task_name.to_s] if @tasks.include? task_name.to_s
        super
      end

      def can_run_sample?(code_sample)
        if known_task? :run_sample
          9
        else
          nil
        end
      end

      def command_for_sample(code_sample)
        command_for_task(:run_sample)
      end
    end

    Crosstest::Psychic::TaskFactoryRegistry.register(HotReadTaskFactory)
  end
end
