module Crosstest
  class Psychic
    class FactoryManager
      include Crosstest::Core::Logger

      BUILT_IN_DIR = File.expand_path('../factories', __FILE__)

      class << self
        def autoload_factories!
          # Load built-in task factories
          Dir.glob("#{BUILT_IN_DIR}/*.rb", File::FNM_CASEFOLD).each do |task_factory_file|
            require task_factory_file
          end
        end

        def factory_classes
          @factory_classes ||= Set.new
        end

        def register_factory(klass)
          factory_classes.add klass
        end

        def clear
          factory_classes.clear
        end
      end

      attr_reader :factories

      def initialize(*args)
        @factories = self.class.factory_classes.map { |k| k.new(*args) }
      end

      def active_factories
        factories.select(&:active?).sort_by(&:priority)
      end

      def active?(klass)
        factories.find do | factory |
          factory.kind_of? klass
        end
      end
    end
  end
end
