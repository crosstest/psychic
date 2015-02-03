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

    class List < BaseCLI
      desc 'scripts', 'Lists known scripts'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      def scripts
        scripts = psychic.known_scripts.map do |script|
          [set_color(script.name, :bold), script.source_file]
        end
        print_table scripts
      end

      desc 'tasks', 'List known tasks'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      def tasks # rubocop:disable Metrics/AbcSize
        psychic.known_tasks.map do |task|
          task_id = set_color(task, :bold)
          if options[:verbose]
            details = psychic.task(task)
            details = "\n#{details}".lines.join('  ') if details.lines.size > 1
            say "#{task_id}: #{details}"
          else
            say task_id
          end
        end
      end
    end

    class Show < BaseCLI
      desc 'script <name>', 'Show detailed information about a script'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      def script(script_name)
        script = psychic.script(script_name)
        say script.to_s(options[:verbose])
      end
    end

    class CLI < BaseCLI
      BUILT_IN_TASKS = %w(bootstrap)

      desc 'task <name>', 'Executes any task by name'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      method_option :os, desc: "Target OS (default value is `RbConfig::CONFIG['host_os']`)"
      method_option :travis, type: :boolean, desc: "Enable/disable delegation to travis-build, if it's available"
      method_option :print, aliases: '-p', desc: 'Print the command (or script) instead of running it'
      def task(task_alias = nil) # rubocop:disable Metrics/AbcSize
        abort 'You must specify a task name, run `psychic list tasks` for a list of known tasks' unless task_alias
        command = psychic.task(task_alias)
        if options[:print]
          say command
        else
          psychic.execute(command, *extra_args)
        end
      rescue TaskNotImplementedError => e
        abort "No usable command was found for task #{task_alias}"
      rescue Crosstest::Shell::ExecutionError => e
        say_status :failed, task_alias, :red
        say e.execution_result if e.execution_result
      end

      BUILT_IN_TASKS.each do |task_alias|
        desc task_alias, "Executes the #{task_alias} task"
        method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
        method_option :cwd, desc: 'Working directory for detecting and running commands'
        define_method(task_alias) do
          task(task_alias)
        end
      end

      desc 'script <name>', 'Executes a script'
      method_option :verbose, aliases: '-v', desc: 'Verbose: display more details'
      method_option :cwd, desc: 'Working directory for detecting and running commands'
      method_option :interactive, desc: 'Prompt for parameters?', enum: %w(always missing), lazy_default: 'missing'
      method_option :parameters, desc: 'YAML file containing key/value parameters. Default: psychic-parameters.yaml'
      method_option :parameter_mode, desc: 'How should the parameters be passed?', enum: %w(tokens arguments env)
      method_option :os, desc: "Target OS (default value is `RbConfig::CONFIG['host_os']`)"
      method_option :print, aliases: '-p', desc: 'Print the command (or script) instead of running it', lazy_default: true
      def script(script_name = nil) # rubocop:disable Metrics/AbcSize
        abort 'You must specify a script name, run `psychic list scripts` for a list of known scripts' unless script_name
        command = psychic.script(script_name, *extra_args)
        if options[:print]
          say command.command(*extra_args) << "\n"
        else
          command.execute(*extra_args)
        end
      rescue ScriptNotRunnable => e
        abort "No usable command was found for script #{script_name}"
      rescue Crosstest::Shell::ExecutionError => e
        say_status :failed, script_name, :red
        say e.execution_result if e.execution_result
      end

      desc 'list', 'List known tasks or scripts'
      subcommand 'list', List
      desc 'show', 'Show details about a task or script'
      subcommand 'show', Show

      no_commands do
        def show_script(_script_name)
        end
      end
    end
  end
end

# rubocop:enable Metrics/LineLength
