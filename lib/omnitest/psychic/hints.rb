module Omnitest
  class Psychic
    class Hints < Omnitest::Core::Dash
      field :options, Hash, default: {}
      field :tasks, Hash[String => String]
      field :scripts, Hash[String => Pathname]

      def options
        self[:options] ||= {}
      end

      def tasks
        self[:tasks] ||= {}
      end

      def scripts
        self[:scripts] ||= {}
      end
    end
  end
end
