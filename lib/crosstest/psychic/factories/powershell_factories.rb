module Crosstest
  class Psychic
    module Factories
      class PowerShellTaskFactory < MagicTaskFactory
        TASK_PRIORITY = 1
        EXTENSIONS = ['.ps1']
        magic_file 'scripts/*.ps1'
        register_task_factory

        def initialize(psychic, opts = {})
          super
          @known_tasks = Dir["#{cwd}/scripts/*"].map do | script |
            File.basename(script, File.extname(script)) if EXTENSIONS.include?(File.extname(script))
          end
        end

        def task(task_alias)
          task = task_alias.to_s
          script = Dir["#{cwd}/scripts/#{task}{.ps1}"].first
          relativize_cmd(script) if script
        end

        def active?
          true if psychic.os_family == :windows
        end

        private

        def relativize_cmd(cmd)
          cmd = Crosstest::Core::FileSystem.relativize(cmd, cwd)
          "PowerShell -NoProfile -ExecutionPolicy Bypass -File \"#{cmd}\""
        end
      end

      class PowerShellScriptFactory < ScriptFactory
        runs '**.ps1', 5

        def active?
          true if psychic.os_family == :windows
        end

        def script(script)
          script = psychic.task('run_script')
          if script
            "#{script} #{script.source_file}"
          else
            relativize_cmd(script.absolute_source_file)
          end
        end
      end
    end
  end
end
