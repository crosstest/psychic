module Psychic
  class Runner
    class ColdRunnerRegistry
      include Psychic::Logger

      BUILT_IN_DIR = File.expand_path('../cold', __FILE__)

      class << self
        def autoload_runners!
          # Load built-in runners
          Dir["#{BUILT_IN_DIR}/*.rb"].each do |cold_runner_file|
            require cold_runner_file
          end
        end

        def runner_classes
          @runner_classes ||= Set.new
        end

        def register(klass)
          runner_classes.add klass
        end

        def active_runners(opts)
          runners = runner_classes.map { |k| k.new(opts) }
          runners.select(&:active?)
        end
      end
    end
  end
end
