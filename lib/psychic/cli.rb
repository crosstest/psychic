require 'English'
require 'thor'

module Psychic
  class CLI < Thor
    BUILT_IN_TASKS = %w(bootstrap)

    class << self
      # Override Thor's start to strip extra_args from ARGV before it's processed
      attr_accessor :extra_args

      def start(given_args = ARGV, config = {})
        if given_args && (split_pos = given_args.index('--'))
          @extra_args = given_args.slice(split_pos + 1, given_args.length)
          given_args = given_args.slice(0, split_pos)
        end
        super given_args, config
      end
    end

    no_commands do
      def extra_args
        self.class.extra_args
      end
    end
  end
end
