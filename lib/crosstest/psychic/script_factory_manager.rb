module Crosstest
  class Psychic
    class ScriptFactoryManager < FactoryManager
      def factories_for(script)
        active_factories.select do | factory |
          factory.priority_for_script(script)
        end.sort_by do |factory|
          factory.priority_for_script(script)
        end
      end
    end
  end
end
