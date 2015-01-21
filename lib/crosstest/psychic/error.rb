module Crosstest
  class Psychic
    class TaskNotImplementedError < NotImplementedError
      def initialize(task_name)
        super("task #{task_name} is not implemented")
      end
    end

    class SampleNotRunnable < NotImplementedError
      def initialize(code_sample)
        super("psychic does not know how to run #{code_sample.source_file}")
      end
    end
  end
end
