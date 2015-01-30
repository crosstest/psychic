require 'English'

module Crosstest
  module Shell
    class ExecutionError < StandardError
      attr_accessor :execution_result
    end

    # Stores the result of running a command
    class ExecutionResult
      # @return [String] the command that was executed
      attr_reader :command
      # @return [Integer] the exit code of the process
      attr_reader :exitstatus
      # @return [String] the captured standard output
      attr_reader :stdout
      # @return [String] the captured standard error
      attr_reader :stderr

      include Crosstest::Core::Util::Hashable

      # @api private
      def initialize(results)
        @command = results.fetch(:command)
        @exitstatus = results.fetch(:exitstatus)
        # Needs to be UTF-8 to serialize as YAML
        # FIXME: But is serializing to YAML still necessary? Have been using PStore.
        @stdout = results.fetch(:stdout).force_encoding('utf-8')
        @stderr = results.fetch(:stderr).force_encoding('utf-8')
      end

      # @return [Boolean] true if the command succeeded (exit code 0)
      def successful?
        @exitstatus == 0
      end

      # Check if the command succeeded and raises and error if it did not.
      # @raises [ExecutionError] if the command did not succeed
      def error!
        unless successful?
          error = ExecutionError.new "#{command} returned exit code #{exitstatus}"
          error.execution_result = self
          fail error
        end
      end

      # @return [String] a textual summary of the results
      def to_s
        ''"
        Execution Result:
          command: #{command}
          exitstatus: #{exitstatus}
          stdout:
        #{stdout}
          stderr:
        #{stderr}
        "''
      end
    end
  end
end
