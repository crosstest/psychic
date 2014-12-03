autoload :Mustache, 'mustache'

module Psychic
  class RegexpTokenHandler
    def initialize(template, token_pattern, token_replacement)
      @template = template
      @token_pattern = token_pattern
      @token_replacement = token_replacement
    end

    def tokens
      @template.scan(@token_pattern).flatten.uniq
    end

    def replace(variables = {})
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

    def replace(variables = {})
      Mustache.render(@template, variables)
    end
  end
end
