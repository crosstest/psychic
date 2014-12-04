require 'English'
require 'thor'
require 'psychic/runner'

module Psychic
  class CLI < Thor
    BUILT_IN_TASKS = %w(bootstrap)

    class << self
      # Override Thor's start to strip extra_args from ARGV before it's processed
      attr_accessor :extra_args

      def start(given_args = ARGV, config = {})
        if given_args && (split_pos = given_args.index('--'))
          @extra_args = given_args.slice(split_pos + 1, given_args.length)
          given_args = given_args.slice(0, split_pos)
        end
        super given_args, config
      end
    end

    no_commands do
      def extra_args
        self.class.extra_args
      end
    end

    desc 'task <name>', 'Executes any task by name'
    def task(task_name)
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
      parameters_file = options.parameters
      parameters_file ||= 'psychic-parameters.yaml' if File.exist? DEFAULT_PARAMS_FILE
      if parameters_file
        fail "Parameter file #{parameters_file} does not exist" unless File.exist? parameters_file
        parameters = load_parameters_file(parameters_file)
      end
      runner_opts = Util.symbolized_hash(options).merge(
        cwd: Dir.pwd, cli: shell, parameters: parameters
      )
      @runner ||= Psychic::Runner.new(runner_opts)
    end
  end
end
