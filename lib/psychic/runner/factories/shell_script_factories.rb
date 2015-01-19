module Psychic
  class Runner
    module Factories
      class ShellScriptTaskFactory < MagicTaskFactory
        TASK_PRIORITY = 1
        EXTENSIONS = ['.sh', '']
        magic_file 'scripts/*'
        register_task_factory
        runs '.sh', 5
        runs '*', 1

        def initialize(opts)
          super
          @known_tasks = Dir["#{@cwd}/scripts/*"].map do | script |
            File.basename(script, File.extname(script)) if EXTENSIONS.include?(File.extname(script))
          end
        end

        def task_for(task_name)
          task = task_name.to_s
          script = Dir["#{@cwd}/scripts/#{task}{.sh,}"].first
          relativize_cmd(script) if script
        end

        def task_for_sample(code_sample)
          script = task_for('run_sample')
          if script
            "#{script} #{code_sample.source_file}"
          else
            relativize_cmd(code_sample.absolute_source_file)
          end
        end

        def active?
          true
        end

        private

        def relativize_cmd(cmd)
          cmd = Psychic::Util.relativize(cmd, @cwd)
          "./#{cmd}" unless cmd.to_s.start_with? '/'
        end
      end
    end
  end
end
