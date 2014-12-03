require 'thor'
require 'psychic/runner'

module Psychic
  class CLI < Thor
    desc 'run_task <name>', 'Executes a custom task by name'
    def run_task(task_name)
      result = runner.execute_task(task_name)
      result.error!
      say_status :success, task_name
    rescue Psychic::Shell::ExecutionError => e
      say_status :failed, task_name, :red
      say e.execution_result if e.execution_result
    end

    desc 'run_sample <name>', 'Executes a code sample'
    def run_sample(sample_name)
      result = runner.run_sample(sample_name)
      result.error!
      say_status :success, sample_name
    rescue Errno::ENOENT => e
      say_status :failed, "No code sample found for #{sample_name}", :red
    rescue Psychic::Shell::ExecutionError => e
      say_status :failed, "Executing sample #{sample_name}", :red
      say e.execution_result if e.execution_result
    end

    private

    def runner
      # Psychic::Shell.shell = shell
      @runner ||= Psychic::Runner.new
    end
  end
end

# require 'psychic/commands/exec'
