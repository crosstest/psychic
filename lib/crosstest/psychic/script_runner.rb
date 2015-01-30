module Crosstest
  class Psychic
    module ScriptRunner
      def script_factory_manager
        @script_factory_manager ||= ScriptFactoryManager.new(self, opts)
      end

      def known_scripts
        @known_scripts ||= hints.scripts.map do | script_name, script_file |
          Script.new(self, script_name, script_file, self.opts)
        end
      end

      def script(script_name)
        find_in_known_scripts(script_name) || find_in_basedir(script_name)
      end

      protected

      def find_in_known_scripts(script_name)
        known_scripts.find do |script|
          script.name.downcase == script_name.downcase
        end
      end

      def find_in_basedir(script_name) # rubocop:disable Metrics/AbcSize
        file = FileFinder.find_file_by_alias(script_name, basedir) do | files |
          candidates = files.group_by do | script_file |
            # Chooses the file w/ the highest chance of being runnable
            path = Crosstest::Core::FileSystem.relativize(script_file, cwd)
            script = Script.new(self, script_name, path, self.opts)
            script_factory_manager.priority_for(script) || 0
          end
          candidates.empty? ? files.first : candidates[candidates.keys.max].min_by(&:length)
        end

        return nil if file.nil?

        Script.new(self, script_name, file, self.opts).tap do | script |
          @known_scripts << script
        end
      end
    end
  end
end
