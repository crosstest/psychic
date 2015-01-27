module Crosstest
  class Psychic
    class TaskNotImplementedError < NotImplementedError
      def initialize(task_name)
        super("no active task factories can run a task named #{task_name}")
      end
    end

    class SampleNotRunnable < NotImplementedError
      def initialize(code_sample)
        super("no active script factories no how to run #{code_sample.source_file}")
      end
    end
  end
end
