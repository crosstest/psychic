module Psychic
  class Runner
    class TaskFactoryRegistry
      include Psychic::Logger

      BUILT_IN_DIR = File.expand_path('../factories', __FILE__)

      class << self
        def autoload_task_factories!
          # Load built-in task factories
          Dir["#{BUILT_IN_DIR}/*.rb"].each do |task_factory_file|
            require task_factory_file
          end
        end

        def task_factory_classes
          @task_factory_classes ||= Set.new
        end

        def register(klass)
          task_factory_classes.add klass
        end

        def active_task_factories(opts)
          task_factories = task_factory_classes.map { |k| k.new(opts) }
          task_factories.select(&:active?).sort_by(&:priority)
        end
      end
    end
  end
end
