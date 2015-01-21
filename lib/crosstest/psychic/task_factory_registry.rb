module Crosstest
  class Psychic
    class TaskFactoryRegistry
      include Crosstest::Core::Logger

      BUILT_IN_DIR = File.expand_path('../factories', __FILE__)

      class << self
        def autoload_task_factories!
          # Load built-in task factories
          Dir.glob("#{BUILT_IN_DIR}/*.rb", File::FNM_CASEFOLD).each do |task_factory_file|
            require task_factory_file
          end
        end

        def activate_task_factories(runner, opts)
          task_factories = task_factory_classes.map { |k| k.new(runner, opts) }
          task_factories.select(&:active?).sort_by(&:priority)
        end

        def task_factory_classes
          @task_factory_classes ||= Set.new
        end

        def register(klass)
          task_factory_classes.add klass
        end
      end
    end
  end
end
