module Crosstest
  class Psychic
    class TaskFactoryManager < FactoryManager
      def factories_for(task)
        active_factories.select do | factory |
          factory.priority_for_task(task)
        end.sort_by do |factory|
          factory.priority_for_task(task)
        end
      end

      def known_tasks
        active_factories.flat_map(&:known_tasks)
      end
    end
  end
end
