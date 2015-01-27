module Crosstest
  class Psychic
    class TaskFactoryManager < FactoryManager
      def factory_for(code_sample)
        tf = active_factories.sort_by do |factory|
          factory.priority || 0
        end.last
      end
    end
  end
end
