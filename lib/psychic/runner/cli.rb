require 'psychic/cli'
require 'psychic/runner'

module Psychic
  class Runner
    class CLI < Psychic::CLI
      desc 'task <name>', 'Executes any task by name'
      method_option :list, aliases: '-l', desc: 'List known tasks'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      def task(task_name = nil)
        return list_tasks if options[:list]
        abort 'You must specify a task name, run with -l for a list of known tasks'
        result = runner.execute_task(task_name, *extra_args)
        result.error!
        say_status :success, task_name
      rescue Psychic::Shell::ExecutionError => e
        say_status :failed, task_name, :red
        say e.execution_result if e.execution_result
      end

      BUILT_IN_TASKS.each do |task_name|
        desc task_name, "Executes the #{task_name} task"
        define_method(task_name) do
          task(task_name)
        end
      end

      desc 'sample <name>', 'Executes a code sample'
      # rubocop:disable Metrics/LineLength
      method_option :interactive, desc: 'Prompt for parameters?', enum: %w(always missing), lazy_default: 'missing'
      method_option :parameters, desc: 'YAML file containing key/value parameters. Default: psychic-parameters.yaml'
      method_option :parameter_mode, desc: 'How should the parameters be passed?', enum: %w(tokens arguments env)
      method_option :dry_run, desc: 'Do not execute - just show what command would be run', lazy_default: true
      # rubocop:enable Metrics/LineLength
      def sample(*sample_names)
        sample_names.each do | sample_name |
          say_status :executing, sample_name
          begin
            run_sample sample_name
          rescue Errno::ENOENT
            say_status :failed, "No code sample found for #{sample_name}", :red
            # TODO: Fail on missing? Fail fast?
          end
        end
      end

      no_commands do
        def list_tasks
          runner.known_tasks.map do |task|
            task_id = set_color(task, :bold)
            if options[:verbose]
              details = runner[task]
              details = "\n#{details}".lines.join('  ') if details.lines.size > 1
              say "#{task_id}: #{details}"
            else
              say "  #{task_id}"
            end
          end
        end
      end

      private

      def run_sample(sample_name)
        result = runner.run_sample(sample_name, *extra_args)
        if options.dry_run
          say_status :dry_run, sample_name
        else
          result.error!
          say_status :success, sample_name
        end
      end

      def runner
        @runner ||= setup_runner
      end

      def setup_runner
        runner_opts = { cwd: Dir.pwd, cli: shell, parameters: options.parameters }
        runner_opts.merge!(Util.symbolized_hash(options))
        Psychic::Runner.new(runner_opts)
      end
    end
  end
end
