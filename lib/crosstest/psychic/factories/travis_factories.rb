module Crosstest
  class Psychic
    module Factories
      class TravisTaskFactory < MagicTaskFactory
        TASK_PRIORITY = 2
        magic_file '.travis.yml'
        register_task_factory

        def active?
          super && travis_allowed? && travis_build_installed?
        end

        def travis_allowed?
          psychic.opts[:travis]
        end

        def travis_build_installed?
          # check that the travis-build extension is installed
          # HACK: use the MixlibShellOutExecutor
          Bundler.with_clean_env { `travis help --skip-version-check`.match(/run/) }
        end

        task :bootstrap do
          'travis run --skip-version-check install'
        end

        task :test do
          'travis run --skip-version-check script'
        end
      end
    end
  end
end
