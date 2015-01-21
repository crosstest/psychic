module Crosstest
  class Psychic
    module Factories
      class BundlerTaskFactory < MagicTaskFactory
        TASK_PRIORITY = 2
        magic_file 'Gemfile'
        magic_file '.bundle/config'
        magic_env_var 'BUNDLE_GEMFILE'
        register_task_factory
        runs '*.rb'

        def active?
          # Avoid detecting crosstest's own BUNDLE_GEMFILE variable
          Bundler.with_clean_env do
            super
          end
        end

        task :bootstrap do
          'bundle install'
        end

        task :run_sample do
          'bundle exec ruby {{sample_file}}'
        end
      end
    end
  end
end
