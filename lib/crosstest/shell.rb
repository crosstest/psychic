module Crosstest
  module Shell
    autoload :ExecutionResult, 'crosstest/shell/execution_result'
    autoload :ExecutionError, 'crosstest/shell/execution_result'
    autoload :MixlibShellOutExecutor, 'crosstest/shell/mixlib_shellout_executor'
    autoload :BuffShellOutExecutor, 'crosstest/shell/buff_shellout_executor'

    AVAILABLE_OPTIONS = [
      # All MixLib::ShellOut options - though we don't use most of these
      :cwd, :domain, :password, :user, :group, :umask,
      :timeout, :returns, :live_stream, :live_stdout,
      :live_stderr, :input, :logger, :log_level, :log_tag, :env
    ]

    attr_writer :shell

    def shell
      @shell ||= RUBY_PLATFORM == 'java' ? BuffShellOutExecutor.new : MixlibShellOutExecutor.new
    end

    attr_writer :shell

    def cli
      @cli ||= Thor::Shell::Base.shell
    end
  end
end
