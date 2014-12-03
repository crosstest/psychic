require 'English'

module Psychic
  module Shell
    class ExecutionError < StandardError
      attr_accessor :execution_result
    end

    class ExecutionResult
      attr_reader :exitstatus
      attr_reader :stdout
      attr_reader :stderr
      # coerce_value String, ->(v) { v.force_encoding('utf-8') }

      include Psychic::Util::Hashable

      def initialize(results)
        @exitstatus = results.fetch(:exitstatus)
        # Needs to be UTF-8 to serialize as YAML
        @stdout = results.fetch(:stdout).force_encoding('utf-8')
        @stderr = results.fetch(:stderr).force_encoding('utf-8')
      end

      def error!
        if @exitstatus != 0
          error = ExecutionError.new
          error.execution_result = self
          fail error
        end
      end

      def to_s
        ''"
        Execution Result:
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
