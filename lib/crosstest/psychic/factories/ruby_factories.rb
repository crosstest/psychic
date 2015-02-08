module Crosstest
  class Psychic
    module Factories
      module UsesBundler
        def bundle_command
          bundler_active? ? 'bundle exec ' : ''
        end

        protected

        def bundler_active?
          psychic.task_factory_manager.active? BundlerTaskFactory
        end
      end

      class BundlerTaskFactory < MagicTaskFactory
        TASK_PRIORITY = 2
        magic_file 'Gemfile'
        magic_file '.bundle/config'
        magic_env_var 'BUNDLE_GEMFILE'
        register_task_factory

        def active?
          # Avoid detecting crosstest's own BUNDLE_GEMFILE variable
          Bundler.with_clean_env do
            super
          end
        end

        task :bootstrap do
          'bundle install'
        end
      end

      class RakeFactory < MagicTaskFactory
        include UsesBundler
        magic_file 'Rakefile'
        register_task_factory

        task :test do
          [bundle_command, "rake"].join
        end
      end

      class RubyFactory < ScriptFactory
        include UsesBundler
        register_script_factory
        runs '**.rb', 8

        def script(script)
          [bundle_command, "ruby #{script.source_file}"].join
        end
      end
    end
  end
end
