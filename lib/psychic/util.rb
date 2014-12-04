module Psychic
  autoload :RegexpTokenHandler, 'psychic/tokens'
  autoload :MustacheTokenHandler, 'psychic/tokens'
  class Util
    module Hashable
      def to_hash
        instance_variables.each_with_object({}) do |var, hash|
          hash[var.to_s.delete('@')] = instance_variable_get(var)
        end
      end
    end
    # Returns a new Hash with all key values coerced to strings. All keys
    # within a Hash are coerced by calling #to_s and hashes with arrays
    # and other hashes are traversed.
    #
    # @param obj [Object] the hash to be processed. While intended for
    #   hashes, this method safely processes arbitrary objects
    # @return [Object] a converted hash with all keys as strings
    def self.stringified_hash(obj)
      if obj.is_a?(Hash)
        obj.each_with_object({}) do |(k, v), h|
          h[k.to_s] = stringified_hash(v)
        end
      elsif obj.is_a?(Array)
        obj.each_with_object([]) do |e, a|
          a << stringified_hash(e)
        end
      else
        obj
      end
    end

    def self.symbolized_hash(obj)
      if obj.is_a?(Hash)
        obj.each_with_object({}) do |(k, v), h|
          h[k.to_sym] = symbolized_hash(v)
        end
      elsif obj.is_a?(Array)
        obj.each_with_object([]) do |e, a|
          a << symbolized_hash(e)
        end
      else
        obj
      end
    end

    def self.relativize(file, base_path)
      absolute_file = File.absolute_path(file)
      absolute_base_path = File.absolute_path(base_path)
      Pathname.new(absolute_file).relative_path_from Pathname.new(absolute_base_path)
    end

    def self.slugify(*labels)
      labels.map do |label|
        label.downcase.gsub(/[\.\s-]/, '_')
      end.join('-')
    end

    def self.find_file_by_alias(file_alias, search_path, ignored_patterns = nil)
      FileFinder.new(search_path, ignored_patterns).find_file(file_alias)
    end

    def self.replace_tokens(template, variables, token_regexp = nil, token_replacement = nil)
      if token_regexp.nil?
        MustacheTokenHandler.new(template).render(variables)
      else
        RegexpTokenHandler.new(template, token_regexp, token_replacement).render(variables)
      end
    end
  end

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
      Psychic::Util.relativize(file, search_path)
    end

    def potential_files(name)
      slugified_name = Psychic::Util.slugify(name)
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
        file = Psychic::Util.relativize(target_file, search_path)
        ignored = file.fnmatch? pattern
        ignored || (file.fnmatch? "**/#{pattern}" unless started_with_slash)
      end
    end
  end
end
