module Crosstest
  class Psychic
    class ScriptFinder
      attr_accessor :hints

      def initialize(search_dir = Dir.pwd, hints = nil)
        @search_dir = search_dir
        @hints = hints || {}
      end

      def known_scripts
        hints.map do | name, file |
          CodeSample.new(name: name, source_file: file, basedir: @search_dir)
        end
      end

      def find_script(name)
        file = find_in_hints(name) || FileFinder.find_file_by_alias(name, @search_dir)
        CodeSample.new(name: name, source_file: file, basedir: @search_dir)
      end

      private

      def find_in_hints(name)
        hints.samples.each do |k, v|
          return v if k.downcase == name.downcase
        end
        nil
      end
    end
  end
end
