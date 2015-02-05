module Crosstest
  class Psychic
    module Execution
      class EnvStrategy < DefaultStrategy
        def execute(*extra_args)
          script.env.merge!(script.params)
          super
        end
      end
    end
  end
end
