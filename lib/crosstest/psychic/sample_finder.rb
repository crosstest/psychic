module Crosstest
  class Psychic
    class SampleFinder
      attr_accessor :hints

      def initialize(search_dir = Dir.pwd, hints = nil)
        @search_dir = search_dir
        @hints = hints || {}
      end

      def known_samples
        hints.map do | name, file |
          CodeSample.new(name, file, @search_dir)
        end
      end

      def find_sample(name)
        file = find_in_hints(name) || FileFinder.find_file_by_alias(name, @search_dir)
        CodeSample.new(name, file, @search_dir)
      end

      # Find multiple samples by a regex or glob pattern
      # def find_samples(pattern)
      # end

      private

      def find_in_hints(name)
        hints.each do |k, v|
          return v if k.downcase == name.downcase
        end
        nil
      end
    end
  end
end
