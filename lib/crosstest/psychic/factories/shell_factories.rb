module Crosstest
  class Psychic
    module Factories
      module ShellBase
        EXTENSIONS = ['.sh', '']

        def active?
          true unless psychic.os_family == :windows
        end

        protected

        def relativize_cmd(cmd)
          cmd = Crosstest::Core::FileSystem.relativize(cmd, cwd)
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
          @known_tasks = Dir.glob("#{cwd}/scripts/*", File::FNM_CASEFOLD).map do | script |
            File.basename(script, File.extname(script)) if EXTENSIONS.include?(File.extname(script))
          end
        end

        def task(task_alias)
          task = task_alias.to_s
          script = Dir.glob("#{cwd}/scripts/#{task}{.sh,}", File::FNM_CASEFOLD).first
          relativize_cmd(script) if script
        end
      end

      class ShellScriptFactory < ScriptFactory
        include ShellBase
        register_script_factory
        runs '**.sh', 5

        def shell_task_factory
          psychic.task_factory_manager.active? ShellTaskFactory
        end

        def priority_for_script(script)
          return 8 if shell_task_factory.known_task? :run_script

          case script.extname
          when '.sh'
            9
          when ''
            7
          else
            5 if shebang?(script)
          end
        end

        def script(script)
          base_command = run_script_command
          if base_command
            "#{base_command} #{script.source_file}"
          else
            relativize_cmd(script.absolute_source_file)
          end
        end

        protected

        def run_script_command
          psychic.task('run_script')
        rescue TaskNotImplementedError
          nil
        end

        def shebang?(script)
          first_line = script.source.lines.first
          first_line && first_line.match(/\#\!/)
        rescue => e
          logger.warn("Could not read #{script.source_file}: #{e.message}")
          # Could be binary, unknown encoding, ...
          false
        end
      end
    end
  end
end
