module Crosstest
  class Psychic
    module Factories
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

      class RubyFactory < ScriptFactory
        register_script_factory
        runs_extension 'rb'

        def command_for_sample(code_sample)
          cmd = bundler_active? ? "bundle exec " : ""
          cmd << "ruby {{sample_file}}"
        end

        protected

        def bundler_active?
          task_runner.task_factory_manager.active? BundlerTaskFactory
        end
      end
    end
  end
end
