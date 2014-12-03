module Psychic
  module Shell
    autoload :ExecutionResult, 'psychic/shell/execution_result'
    autoload :ExecutionError, 'psychic/shell/execution_result'
    autoload :MixlibShellOutExecutor, 'psychic/shell/mixlib_shellout_executor'

    class << self
      attr_writer :shell
    end

    def self.shell
      @shell ||=  MixlibShellOutExecutor.new
    end

    def shell
      Psychic::Shell.shell
    end
  end
end
