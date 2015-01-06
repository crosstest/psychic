module Psychic
  class Runner
    module Cold
      class BundlerDetector
        include BaseRunner
        magic_file 'Gemfile'
        magic_file '.bundle/config'
        magic_env_var 'BUNDLE_GEMFILE'
        register_runner

        task :bootstrap do
          'bundle install'
        end
      end
    end
  end
end
