autoload :Mustache, 'mustache'

module Crosstest
  class Psychic
    module Tokens
      class RegexpTokenHandler
        def initialize(template, token_pattern, token_replacement)
          @template = template
          @token_pattern = token_pattern
          @token_replacement = token_replacement
        end

        def tokens
          @template.scan(@token_pattern).flatten.uniq
        end

        def render(variables = {})
          @template.gsub(@token_pattern) do
            full_match = Regexp.last_match[0]
            key = Regexp.last_match[1]
            value = variables[key]
            value = @token_replacement.gsub('\\1', value.to_s) unless @token_replacement.nil?
            full_match.gsub(@token_pattern, value)
          end
        end
      end

      class MustacheTokenHandler
        def initialize(template)
          @template = Mustache::Template.new(template)
        end

        def tokens
          @template.tags
        end

        def render(variables = {})
          Mustache.render(@template, variables)
        end
      end

      def self.replace_tokens(template, variables, token_regexp = nil, token_replacement = nil)
        if token_regexp.nil?
          MustacheTokenHandler.new(template).render(variables)
        else
          RegexpTokenHandler.new(template, token_regexp, token_replacement).render(variables)
        end
      end
    end
  end
end
