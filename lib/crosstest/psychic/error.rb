module Crosstest
  class Psychic
    class TaskNotImplementedError < NotImplementedError
      def initialize(task_name)
        super("no active task factories can run a task named #{task_name}")
      end
    end

    class ScriptNotRunnable < NotImplementedError
      def initialize(script)
        super("no active script factories no how to run #{script.source_file}")
      end
    end
  end
end
