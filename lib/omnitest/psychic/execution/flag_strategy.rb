module Omnitest
  class Psychic
    module Execution
      class FlagStrategy < DefaultStrategy
        def execute(*extra_args)
          script.params.each do |key, value |
            extra_args << "--#{key}=#{value}"
          end
          super
        end
      end
    end
  end
end
