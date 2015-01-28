module Crosstest
  class Psychic
    class Hints < Crosstest::Core::Dash
      field :options, Hash, default: {}
      field :tasks, Hash[String => String]
      field :samples, Hash[String => Pathname]

      def options
        self[:options] ||= {}
      end

      def tasks
        self[:tasks] ||= {}
      end

      def samples
        self[:samples] ||= {}
      end
    end
  end
end
