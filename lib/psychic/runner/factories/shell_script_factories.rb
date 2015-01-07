module Psychic
  class Runner
    module Factories
      class ShellScriptTaskFactory < MagicTaskFactory
        include BaseRunner
        EXTENSIONS = ['.sh', '']
        magic_file 'scripts/*'
        register_task_factory

        def initialize(opts)
          super
          @known_tasks = Dir["#{@cwd}/scripts/*"].map do | script |
            File.basename(script, File.extname(script)) if EXTENSIONS.include?(File.extname(script))
          end
        end

        def task_for(task_name)
          task = task_name.to_s
          script = Dir["#{@cwd}/scripts/#{task}{.sh,}"].first
          if script
            cmd = Psychic::Util.relativize(script, @cwd)
            cmd = [cmd, args_for_task(task_name)].compact.join(' ')
            "./#{cmd}" unless cmd.to_s.start_with? '/'
          end
        end

        def args_for_task(task)
          # HACK: Need a better way to deal with args
          '{{sample_file}}' if task == 'run_sample'
        end

        def active?
          true
        end
      end
    end
  end
end
