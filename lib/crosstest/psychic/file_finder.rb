module Crosstest
  class Psychic
    class FileFinder
      attr_reader :search_path, :ignored_patterns

      def initialize(search_path, ignored_patterns)
        @search_path = search_path
        @ignored_patterns = ignored_patterns || read_gitignore(search_path)
      end

      # Finds a file by loosely matching the file name to a scenario name
      def find_file(name)
        return name if File.exist? File.expand_path(name, search_path)

        # Filter out ignored filesFind the first file, not including generated files
        files = potential_files(name).select do |f|
          !ignored? f
        end

        # Select the shortest path, likely the best match
        file = files.min_by(&:length)

        fail Errno::ENOENT, "No file was found for #{name} within #{search_path}" if file.nil?
        Crosstest::Core::FileSystem.relativize(file, search_path)
      end

      def potential_files(name)
        slugified_name = Crosstest::Core::FileSystem.slugify(name)
        glob_string = "#{search_path}/**/*#{slugified_name}*.*"
        potential_files = Dir.glob(glob_string, File::FNM_CASEFOLD)
        potential_files.concat Dir.glob(glob_string.gsub('_', '-'), File::FNM_CASEFOLD)
        potential_files.concat Dir.glob(glob_string.gsub('_', ''), File::FNM_CASEFOLD)
      end

      private

      # @api private
      def read_gitignore(dir)
        gitignore_file = "#{dir}/.gitignore"
        File.read(gitignore_file)
      rescue
        ''
      end

      # @api private
      def ignored?(target_file)
        # Trying to match the git ignore rules but there's some discrepencies.
        ignored_patterns.split.find do |pattern|
          # if git ignores a folder, we should ignore all files it contains
          pattern = "#{pattern}**" if pattern[-1] == '/'
          started_with_slash = pattern.start_with? '/'

          pattern.gsub!(%r{\A/}, '') # remove leading slashes since we're searching from root
          file = Crosstest::Core::FileSystem.relativize(target_file, search_path)
          ignored = file.fnmatch? pattern
          ignored || (file.fnmatch? "**/#{pattern}" unless started_with_slash)
        end
      end

      def self.find_file_by_alias(file_alias, search_path, ignored_patterns = nil)
        FileFinder.new(search_path, ignored_patterns).find_file(file_alias)
      end
    end
  end
end
