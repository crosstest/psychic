module Crosstest
  class Psychic
    module TaskRunner
      def task_factory_manager
        @task_factory_manager ||= TaskFactoryManager.new(self, opts)
      end

      def known_tasks
        task_factory_manager.known_tasks
      end

      def command_for_task(task_name, *args)
        task_factory = task_factory_manager.factories_for(task_name).last
        fail TaskNotImplementedError, task_name if task_factory.nil? || task_factory.priority == 0
        command = task_factory.command_for_task(task_name)
        CommandTemplate.new(command, parameters, *args)
      end

      def execute_task(task_name, *args)
        command = command_for_task(task_name, *args)
        execute(command, *args)
      end
    end
  end
end
