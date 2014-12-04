module Psychic
  class Runner
    class HotRunner
      include BaseRunner
      def initialize(opts = {})
        super
        @tasks = hints['tasks'] || {}
        @known_tasks = @tasks.keys
      end

      def [](task_name)
        @tasks[task_name]
      end
    end
  end
end
