module Crosstest
  class Psychic
    class Workflow
      attr_reader :commands, :psychic

      def initialize(psychic, name = 'workflow', options = {}, &block)
        @psychic = psychic
        @name = name
        @options = options
        @commands = []
        instance_eval &block if block_given?
      end

      def task(name, *args)
        @commands << psychic.task(name, *args)
      end

      def command
        @commands.map(&:command).join("\n") + "\n"
      end

      def execute(_params = {}, shell_opts = {}, *extra_args)
        @psychic.execute(command, shell_opts, *extra_args)
      end
    end
  end
end
