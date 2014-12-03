module Psychic
  module Commands
    class Exec < Thor
      desc 'task <name>', 'Executes a custom task by name'
      def task(task_name)
        # Psychic::Shell.shell = shell
        runner = Psychic::Runner.new
        result = runner.public_send(task_name.to_sym)
        result.error!
        say_status :success, task_name
      rescue Psychic::Shell::ExecutionError => e
        say_status :failed, task_name, :red
        say e.execution_result if e.execution_result
      end
    end
  end
end

Psychic::CLI.register(Psychic::Commands::Exec, 'exec', 'exec <task>', 'Execute things via psychic')
