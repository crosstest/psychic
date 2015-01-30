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

      def priority_for(script)
        active_factories.map do | factory |
          factory.priority_for_script(script) || 0
        end.max
      end
    end
  end
end
