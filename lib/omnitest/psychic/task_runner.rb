module Omnitest
  class Psychic
    module TaskRunner
      # Chooses an appropriate task for the task alias
      # @param [String] task_alias an alias used to lookup a task
      # @return [Task] the best match for the task alias
      def task(task_alias)
        task_alias = task_alias.to_sym
        task_factory = task_factory_manager.factories_for(task_alias).last
        fail TaskNotImplementedError, task_alias if task_factory.nil? || task_factory.priority == 0
        command = task_factory.task(task_alias)
        Task.new(self, command)
      end

      # Lists all known tasks. This will include tasks that have been
      # manually alased in `psychic.yaml`, well-known tasks for detected
      # tools, and possibly some dynamically detected tasks for tools that
      # support task discovery.
      # @return [Set<Task>] the set of known tasks
      def known_tasks
        task_factory_manager.known_tasks
      end

      # @api private
      def task_factory_manager
        @task_factory_manager ||= TaskFactoryManager.new(self, opts)
      end
    end
  end
end
