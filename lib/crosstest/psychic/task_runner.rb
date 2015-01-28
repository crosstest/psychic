module Crosstest
  class Psychic
    module TaskRunner
      def find_task(task_name, *_args)
        task_name = task_name.to_s
        command = command_for_task(task_name)
        command = command.call if command.respond_to? :call
        fail Crosstest::Psychic::TaskNotImplementedError, task_name if command.nil?
        Task.new(task_name, command)
      end

      def execute_task(task_name, *args)
        task = find_task(task_name, *args)
        execute(task.command, *args)
      end
    end
  end
end
