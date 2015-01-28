require 'crosstest/core'
require 'crosstest/psychic'

# rubocop:disable Metrics/LineLength

module Crosstest
  class Psychic
    class BaseCLI < Crosstest::Core::CLI
      no_commands do
        def psychic
          @psychic ||= setup_runner
        end

        def setup_runner
          runner_opts = { cwd: Dir.pwd, cli: shell, parameters: options.parameters }
          runner_opts.merge!(Crosstest::Core::Util.symbolized_hash(options))
          Crosstest::Psychic.new(runner_opts)
        end
      end
    end

    class CLI < BaseCLI
      BUILT_IN_TASKS = %w(bootstrap)

      desc 'task <name>', 'Executes any task by name'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      method_option :os, desc: "Target OS (default value is `RbConfig::CONFIG['host_os']`)"
      method_option :print, aliases: '-p', desc: 'Print the command (or script) instead of running it'
      def task(task_name = nil)
        abort 'You must specify a task name, run `psychic list tasks` for a list of known tasks' unless task_name
        command_template = psychic.command_for_task(task_name)
        abort "No usable command was found for task #{task_name}" if command_template.nil?
        if options[:print]
          say command_template.command({}, *extra_args)
        else
          execute_task task_name, *extra_args
        end
      rescue Crosstest::Shell::ExecutionError => e
        say_status :failed, task_name, :red
        say e.execution_result if e.execution_result
      end

      no_commands do
        def print_task(task_name, *args)
          task = psychic.find_task(task_name)
          say "#{task.command} #{args.join ' '}\n"
        end

        def execute_task(task_name, *args)
          result = psychic.execute_task(task_name, *args)
          result.error!
          say_status :success, task_name
        end

        def print_sample(sample_name, *args)
          sample = psychic.find_script(sample_name)
          say psychic.command_for_sample(sample, *args)
        end

        def execute_sample(sample_name, *args)
          result = psychic.run_sample(sample_name, *args)
          result.error!
          say_status :success, sample_name
        end
      end

      BUILT_IN_TASKS.each do |task_name|
        desc task_name, "Executes the #{task_name} task"
        method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
        method_option :cwd, desc: 'Working directory for detecting and running commands'
        define_method(task_name) do
          task(task_name)
        end
      end

      desc 'sample <name>', 'Executes a code sample'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      method_option :interactive, desc: 'Prompt for parameters?', enum: %w(always missing), lazy_default: 'missing'
      method_option :parameters, desc: 'YAML file containing key/value parameters. Default: psychic-parameters.yaml'
      method_option :parameter_mode, desc: 'How should the parameters be passed?', enum: %w(tokens arguments env)
      method_option :os, desc: "Target OS (default value is `RbConfig::CONFIG['host_os']`)"
      method_option :print, aliases: '-p', desc: 'Print the command (or script) instead of running it', lazy_default: true
      def sample(sample_name = nil)
        abort 'You must specify a sample name, run `psychic list samples` for a list of known samples' unless sample_name
        if options[:print]
          print_sample sample_name, *extra_args
        else
          execute_sample sample_name, *extra_args
        end
      end

      class List < BaseCLI
        desc 'samples', 'Lists known code samples'
        method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
        method_option :cwd, desc: 'Working directory for detecting and running commands'
        def samples
          samples = psychic.known_scripts.map do |sample|
            [set_color(sample.name, :bold), sample.source_file]
          end
          print_table samples
        end

        desc 'tasks', 'List known tasks'
        method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
        method_option :cwd, desc: 'Working directory for detecting and running commands'
        def tasks # rubocop:disable Metrics/AbcSize
          psychic.known_tasks.map do |task|
            task_id = set_color(task, :bold)
            if options[:verbose]
              details = psychic.command_for_task(task)
              details = "\n#{details}".lines.join('  ') if details.lines.size > 1
              say "#{task_id}: #{details}"
            else
              say task_id
            end
          end
        end
      end

      class Show < BaseCLI
        desc 'sample <name>', 'Show detailed information about a code sample'
        method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
        method_option :cwd, desc: 'Working directory for detecting and running commands'
        def sample(sample_name)
          sample = psychic.find_script(sample_name)
          say sample.to_s(options[:verbose])
        end
      end

      desc 'list', 'List known tasks or code samples'
      subcommand 'list', List
      desc 'show', 'Show details about a task or code sample'
      subcommand 'show', Show

      no_commands do
        def show_sample(_sample_name)
        end
      end
    end
  end
end

# rubocop:enable Metrics/LineLength
