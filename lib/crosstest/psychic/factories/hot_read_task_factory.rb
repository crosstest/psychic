module Crosstest
  class Psychic
    module Factories
      class HotReadTaskFactory < MagicTaskFactory
        register_task_factory

        def initialize(psychic, opts = {})
          super
          @tasks = psychic.hints.tasks || {}
          @known_tasks = @tasks.keys || {}
        end

        def active?
          !@tasks.empty?
        end

        def task(task_alias)
          return @tasks[task_alias.to_s] if @tasks.include? task_alias.to_s
          super
        end
      end

      class HotReadScriptFactory < ScriptFactory
        register_script_factory

        def script_hints
          psychic.hints.scripts
        end

        def known_script?(script)
          script_hints.key? script
        end

        def hot_task_factory
          psychic.task_factory_manager.active? HotReadTaskFactory
        end

        def priority_for_script(script)
          if known_script? script
            9
          elsif hot_task_factory.known_task? :run_script
            7
          else
            nil
          end
        end

        def script(script)
          script_hints[script] || hot_task_factory.task(:run_script)
        end
      end
    end
  end
end
