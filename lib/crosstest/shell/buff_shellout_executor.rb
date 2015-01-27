require 'buff/shell_out'

module Crosstest
  module Shell
    class BuffShellOutExecutor
      include Crosstest::Core::Logger
      attr_reader :shell

      def execute(command, opts)
        @logger = opts.delete(:logger) || logger
        cwd = opts[:cwd] || Dir.pwd
        env = opts[:env] || {}
        # @shell.live_stream = IOToLog.new(@logger)
        shell_result = Dir.chdir(cwd) do
          Bundler.with_clean_env do
            Buff::ShellOut.shell_out(command, env)
          end
        end
        execution_result(command, shell_result)
      rescue SystemCallError => e
        execution_error = ExecutionError.new(e)
        # execution_error.execution_result = execution_result(shell_result)
        raise execution_error
      end

      private

      def execution_result(command, shell_result)
        return nil if shell_result.nil?

        ExecutionResult.new(
          command: command,
          exitstatus: shell_result.exitstatus,
          stdout: shell_result.stdout,
          stderr: shell_result.stderr
        )
      end
    end
  end
end
