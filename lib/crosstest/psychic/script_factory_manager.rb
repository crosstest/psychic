module Crosstest
  class Psychic
    class ScriptFactoryManager < FactoryManager
      def find_by_ext(ext)
        active_factories.find { |factory| factory.can_run_extension? ext }
      end

      def factory_for(code_sample)
        sf = active_factories.sort_by do |factory|
          priority = factory.can_run_sample?(code_sample)
          priority ? priority : 0
        end.last
      end
    end
  end
end
