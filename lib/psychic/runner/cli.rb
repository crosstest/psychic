require 'psychic/cli'
require 'psychic/runner'

# rubocop:disable Metrics/LineLength

module Psychic
  class Runner
    class CLI < Psychic::CLI
      desc 'task <name>', 'Executes any task by name'
      method_option :list, aliases: '-l', desc: 'List known tasks'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      def task(task_name = nil)
        return list_tasks if options[:list]
        abort 'You must specify a task name, run with -l for a list of known tasks' unless task_name
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
      method_option :list, aliases: '-l', desc: 'List known tasks'
      method_option :show, aliases: '-s', desc: 'Display details about a sample'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      method_option :interactive, desc: 'Prompt for parameters?', enum: %w(always missing), lazy_default: 'missing'
      method_option :parameters, desc: 'YAML file containing key/value parameters. Default: psychic-parameters.yaml'
      method_option :parameter_mode, desc: 'How should the parameters be passed?', enum: %w(tokens arguments env)
      method_option :dry_run, desc: 'Do not execute - just show what command would be run', lazy_default: true
      def sample(sample_name = nil)
        return list_samples if options[:list]
        abort 'You must specify a sample name, run with -l for a list of known samples' unless sample_name
        show_sample(sample_name) if options[:show]
        result = runner.run_sample(sample_name, *extra_args)
        if options.dry_run
          say_status :dry_run, sample_name
        else
          result.error!
          say_status :success, sample_name
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
              say task_id
            end
          end
        end

        def list_samples
          samples = runner.known_samples.map do |sample|
            [set_color(sample.name, :bold), sample.source_file]
          end
          print_table samples
        end

        def show_sample(sample_name)
          sample = runner.find_sample(sample_name)
          say sample.to_s(options[:verbose])
        end
      end

      private

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

# rubocop:enable Metrics/LineLength
