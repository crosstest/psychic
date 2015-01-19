module Crosstest
  module OutputHelper
    class StringShell < Thor::Base.shell
      attr_reader :io

      def initialize(*args)
        @io = StringIO.new
        super
      end

      alias_method :stdout, :io
      alias_method :stderr, :io

      def string
        @io.string
      end

      def can_display_colors?
        # Still capture colors if they can eventually be displayed.
        $stdout.tty?
      end
    end

    def cli
      @cli ||= Thor::Base.shell.new
    end

    def build_string
      old_cli = @cli
      new_cli = @cli = StringShell.new
      yield
      @cli = old_cli
      new_cli.string
    end

    def reformat(string)
      return if string.nil? || string.empty?

      indent do
        string.gsub(/^/, indent)
      end
    end

    def indent
      @indent_level ||= 0
      if block_given?
        @indent_level += 2
        result = yield
        @indent_level -= 2
        result
      else
        ' ' * @indent_level
      end
    end

    def say(msg)
      cli.say msg if msg
    end

    def status(status, msg = nil, color = :cyan, colwidth = 50)
      msg = yield if block_given?
      cli.say(indent) if indent.length > 0
      status = cli.set_color("#{status}:", color, true)
      # The built-in say_status is right-aligned, we want left-aligned
      cli.say format("%-#{colwidth}s %s", status, msg).rstrip
    end

    # TODO: Reporters for different formats
    def print_table(*args)
      # @reporter.print_table(*args)
      cli.print_table(*args)
    end

    def colorize(string, *args)
      return string unless @reporter.respond_to? :set_color
      # @reporter.set_color(string, *args)
      cli.set_color(string, *args)
    end

    def color_pad(string)
      string + colorize('', :white)
    end
  end
end
