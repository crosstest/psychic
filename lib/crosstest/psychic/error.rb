module Crosstest
  class Psychic
    class TaskNotImplementedError < NotImplementedError
      def initialize(task_alias)
        super("no active task factories can run a task named #{task_alias}")
      end
    end

    class ScriptNotRunnable < NotImplementedError
      def initialize(script)
        super("no active script factories no how to run #{script.source_file}")
      end
    end
  end
end
