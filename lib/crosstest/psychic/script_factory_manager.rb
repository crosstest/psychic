module Crosstest
  class Psychic
    class ScriptFactoryManager < FactoryManager
      def factories_for(code_sample)
        active_factories.select do | factory |
          factory.priority_for_script(code_sample)
        end.sort_by do |factory|
          factory.priority_for_script(code_sample)
        end
      end
    end
  end
end
