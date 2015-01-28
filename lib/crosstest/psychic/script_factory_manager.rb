module Crosstest
  class Psychic
    class ScriptFactoryManager < FactoryManager
      def find_by_ext(ext)
        active_factories.find { |factory| factory.can_run_extension? ext }
      end

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
