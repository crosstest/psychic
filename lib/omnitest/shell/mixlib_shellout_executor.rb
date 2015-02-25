require 'mixlib/shellout'

module Omnitest
  module Shell
    class IOToLog < IO
      def initialize(logger)
        @logger = logger
        @buffer = ''
      end

      def write(string)
        (@buffer + string).lines.each do |line|
          if line.end_with? "\n"
            @buffer = ''
            @logger.info(line.rstrip)
          else
            @buffer = line
          end
        end
      end
    end

    class MixlibShellOutExecutor
      include Omnitest::Core::Logger
      attr_reader :shell

      MIXLIB_SHELLOUT_EXCEPTION_CLASSES = Mixlib::ShellOut.constants.map do|name|
        klass = Mixlib::ShellOut.const_get(name)
        if klass.is_a?(Class) && klass <= RuntimeError
          klass
        else
          nil
        end
      end.compact

      def execute(command, opts = {}) # rubocop:disable Metrics/AbcSize
        opts[:cwd] = (opts[:cwd] || Dir.pwd).to_s
        @logger = opts.delete(:logger) || logger
        @shell = Mixlib::ShellOut.new(command, opts)
        @shell.live_stream = IOToLog.new(@logger)
        Bundler.with_clean_env do
          @shell.run_command
        end
        execution_result
      rescue SystemCallError, *MIXLIB_SHELLOUT_EXCEPTION_CLASSES, TypeError => e
        # See https://github.com/opscode/mixlib-shellout/issues/62
        execution_error = ExecutionError.new(e)
        execution_error.execution_result = execution_result
        raise execution_error
      end

      private

      def execution_result
        return nil if shell.nil?

        ExecutionResult.new(
          command: shell.command,
          exitstatus: shell.exitstatus,
          stdout: shell.stdout,
          stderr: shell.stderr
        )
      end
    end
  end
end
