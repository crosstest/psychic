module Crosstest
  class Psychic
    module Factories
      class HotReadTaskFactory
        include BaseRunner
        register_task_factory

        def initialize(runner, opts = {})
          super
          @tasks = runner.hints.tasks
          @known_tasks = @tasks.keys
        end

        def active?
          !@tasks.empty?
        end

        def command_for_task(task_name)
          return @tasks[task_name.to_s] if @tasks.include? task_name.to_s
          super
        end
      end

      class HotReadScriptFactory < ScriptFactory
        register_script_factory

        def sample_hints
          task_runner.hints.samples
        end

        def known_script?(script)
          sample_hints.key? script
        end

        def hot_task_factory
          task_runner.task_factory_manager.active? HotReadTaskFactory
        end

        def can_run_sample?(code_sample)
          if known_script? code_sample
            9
          elsif hot_task_factory.known_task? :run_sample
            7
          else
            nil
          end
        end

        def command_for_sample(code_sample)
          sample_hints[code_sample] || hot_task_factory.command_for_task(:run_sample)
        end
      end
    end
  end
end
