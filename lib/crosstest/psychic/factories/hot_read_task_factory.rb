module Crosstest
  class Psychic
    module Factories
      class HotReadTaskFactory
        include BaseRunner
        register_task_factory

        def initialize(runner, opts = {})
          super
          @tasks = runner.hints['tasks'] || {}
          @known_tasks = @tasks.keys
        end

        def active?
          !@tasks.empty?
        end

        def command_for_task(task_name)
          return @tasks[task_name.to_s] if @tasks.include? task_name.to_s
          super
        end

        def can_run_sample?(_code_sample)
          if known_task? :run_sample
            9
          else
            nil
          end
        end

        def command_for_sample(_code_sample)
          command_for_task(:run_sample)
        end
      end
    end
  end
end
