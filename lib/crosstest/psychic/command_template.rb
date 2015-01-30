module Crosstest
  class Psychic
    class CommandTemplate
      attr_reader :psychic

      def initialize(psychic, template)
        @psychic = psychic
        fail ArgumentError, 'Cannot create a nil command' if template.nil?
        @template = template
      end

      def command(params = {})
        Tokens.replace_tokens(build_command, params)
      end

      def execute(params = {}, *extra_args)
        @psychic.execute(command(params), *extra_args)
      end

      alias_method :to_s, :command

      private

      def build_command
        @command ||= if @template.respond_to?(:call)
                       @template.call
                     else
                       @template
                     end
      end
    end
  end
end
