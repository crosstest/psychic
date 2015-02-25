module Omnitest
  class Psychic
    module Factories
      class GoFactory < ScriptFactory
        register_script_factory
        runs '**.go', 7

        def script(script)
          "go run {{source_file}}"
        end
      end
    end
  end
end
