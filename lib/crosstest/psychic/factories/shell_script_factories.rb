module Crosstest
  class Psychic
    module Factories
      class ShellScriptTaskFactory < MagicTaskFactory
        TASK_PRIORITY = 1
        EXTENSIONS = ['.sh', '']
        magic_file 'scripts/*'
        register_task_factory
        runs '.sh', 5
        runs '*', 1

        def initialize(*args)
          super
          @known_tasks = Dir.glob("#{@cwd}/scripts/*", File::FNM_CASEFOLD).map do | script |
            File.basename(script, File.extname(script)) if EXTENSIONS.include?(File.extname(script))
          end
        end

        def command_for_task(task_name)
          task = task_name.to_s
          script = Dir.glob("#{@cwd}/scripts/#{task}{.sh,}", File::FNM_CASEFOLD).first
          relativize_cmd(script) if script
        end

        def command_for_sample(code_sample)
          script = command_for_task('run_sample')
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
          cmd = Crosstest::Core::FileSystem.relativize(cmd, @cwd)
          "./#{cmd}" unless cmd.to_s.start_with? '/'
        end
      end
    end
  end
end
