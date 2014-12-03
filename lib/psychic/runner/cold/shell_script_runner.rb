module Psychic
  class Runner
    module Cold
      class ShellScriptRunner
        include BaseRunner
        EXTENSIONS = ['.sh', '']
        magic_file 'scripts/*'
        register_runner

        def initialize(opts)
          super
          @known_tasks = Dir["#{@cwd}/scripts/*"].map do | script |
            File.basename(script, File.extname(script)) if EXTENSIONS.include?(File.extname(script))
          end
        end

        def [](task_name)
          task = task_name.to_s
          script = Dir["#{@cwd}/scripts/#{task}{.sh,}"].first
          if script
            script = Psychic::Util.relativize(script, @cwd)
            "./#{script}" unless script.to_s.start_with? '/'
          end
        end

        def active?
          true
        end
      end
    end
  end
end
