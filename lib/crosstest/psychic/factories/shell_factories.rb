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
          cmd = Crosstest::Core::FileSystem.relativize(cmd, psychic.cwd)
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
        register_script_factory
        runs '**.sh', 5

        def shell_task_factory
          psychic.task_factory_manager.active? ShellTaskFactory
        end

        def priority_for_script(code_sample)
          case code_sample.extname
          when '.sh'
            9
          when ''
            7
          else
            5 if has_shebang?(code_sample)
          end
        end

        def command_for_sample(code_sample)
          script = script_command
          if script
            "#{script} #{code_sample.source_file}"
          else
            relativize_cmd(code_sample.absolute_source_file)
          end
        end

        protected

        def script_command
          psychic.command_for_task('run_sample')
        rescue TaskNotImplementedError
          nil
        end

        def has_shebang?(code_sample)
          first_line = code_sample.source.lines[0]
          first_line && first_line.match(/\#\!/)
        end
      end
    end
  end
end
