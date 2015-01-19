module Psychic
  class Runner
    class CommandTemplate
      def initialize(command_template, params = {})
        @command_template = command_template
        @params = params
        @command = build_command
      end

      def command(params = {}, *args)
        cmd_params = @params.merge(params)
        [Psychic::Util.replace_tokens(@command, cmd_params), *args].join(' ')
      end

      alias_method :to_s, :command

      private

      def build_command
        if @command_template.respond_to?(:call)
          @command_template.call
        else
          @command_template
        end
      end
    end
  end
end
