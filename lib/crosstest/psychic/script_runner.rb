module Crosstest
  class Psychic
    module ScriptRunner
      def script_factory_manager
        @script_factory_manager ||= ScriptFactoryManager.new(self, opts)
      end

      def script_finder
        @script_finder ||= ScriptFinder.new(opts[:cwd], hints)
      end

      def find_script(script)
        return script if script.is_a? Script
        script_finder.find_script(script)
      end

      def known_scripts
        script_finder.known_scripts
      end

      def command_for_script(script, *args)
        script_factory = script_factory_manager.factories_for(script).last

        fail Crosstest::Psychic::ScriptNotRunnable, script if script_factory.nil?
        command = script_factory.command_for_script(script)
        command_params = parameters.merge(
          script: script.name,
          script_file: script.source_file
        )
        CommandTemplate.new(command, command_params, *args)
      end

      def run_script(script_name, *args)
        script = find_script(script_name)
        absolute_script_file = script.absolute_source_file
        process_parameters(absolute_script_file)
        command = command_for_script(script, *args)
        execute(command)
      end

      def process_parameters(script_file)
        if templated?
          backup_and_overwrite(script_file)

          template = File.read(script_file)
          # Default token pattern/replacement (used by php-opencloud) should be configurable
          token_handler = Tokens::RegexpTokenHandler.new(template, /'\{(\w+)\}'/, "'\\1'")
          confirm_or_update_parameters(token_handler.tokens)
          File.write(script_file, token_handler.render(@parameters))
        end
      end

      def templated?
        @parameter_mode == 'tokens'
      end

      def interactive?
        !@interactive_mode.nil?
      end

      protected

      def find_in_hints(script)
        return unless hints.scripts
        hints.scripts.each do |k, v|
          return v if k.downcase == script.downcase
        end
        nil
      end

      def backup_and_overwrite(file)
        backup_file = "#{file}.bak"
        if File.exist? backup_file
          if should_restore?(backup_file, file)
            FileUtils.mv(backup_file, file)
          else
            abort 'Please clear out old backups before rerunning' if File.exist? backup_file
          end
        end
        FileUtils.cp(file, backup_file)
      end

      def should_restore?(file, orig, timing = :before)
        return true if [timing, 'always']. include? @restore_mode
        if interactive?
          @cli.yes? "Would you like to #{file} to #{orig} before running the script?"
        end
      end

      def prompt(key)
        value = @parameters[key]
        if value
          return value unless @interactive_mode == 'always'
          new_value = @cli.ask "Please set a value for #{key} (or enter to confirm #{value.inspect}): "
          new_value.empty? ? value : new_value
        else
          @cli.ask "Please set a value for #{key}: "
        end
      end

      def confirm_or_update_parameters(required_parameters)
        required_parameters.each do | key |
          @parameters[key] = prompt(key)
        end if interactive?
      end
    end
  end
end
