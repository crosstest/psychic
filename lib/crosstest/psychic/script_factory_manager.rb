module Crosstest
  class Psychic
    class ScriptFactoryManager < FactoryManager
      def factories_for(script)
        capable_factories = active_factories.select do | factory |
          factory.priority_for_script(script)
        end

        capable_factories.sort_by do |factory|
          factory.priority_for_script(script)
        end
      end
    end
  end
end
