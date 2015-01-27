module Crosstest
  class Psychic
    module Factories
      module ShellBase
        EXTENSIONS = ['.sh', '']

        def active?
          true unless runner.os_family == :windows
        end

        protected

        def relativize_cmd(cmd)
          cmd = Crosstest::Core::FileSystem.relativize(cmd, @cwd)
          "./#{cmd}" unless cmd.to_s.start_with? '/'
        end
      end

      class ShellTaskFactory < MagicTaskFactory
        include ShellBase
        TASK_PRIORITY = 1
        magic_file 'scripts/*'
        register_task_factory

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
      end

      class ShellScriptFactory < ScriptFactory
        include ShellBase
        runs_extension '.sh', 5
        runs_extension '*', 1

        def command_for_sample(code_sample)
          script = command_for_task('run_sample')
          if script
            "#{script} #{code_sample.source_file}"
          else
            relativize_cmd(code_sample.absolute_source_file)
          end
        end
      end
    end
  end
end
