module Psychic
  class Runner
    module SampleRunner
      def find_sample(code_sample)
        @sample_finder.find_sample(code_sample)
      end

      def run_sample(code_sample_name, *args)
        code_sample = find_sample(code_sample_name)
        absolute_sample_file = code_sample.absolute_source_file
        process_parameters(absolute_sample_file)
        execute(code_sample.command(self), *args)
      end

      def process_parameters(sample_file)
        if templated?
          backup_and_overwrite(sample_file)

          template = File.read(sample_file)
          # Default token pattern/replacement (used by php-opencloud) should be configurable
          token_handler = RegexpTokenHandler.new(template, /'\{(\w+)\}'/, "'\\1'")
          confirm_or_update_parameters(token_handler.tokens)
          File.write(sample_file, token_handler.render(@parameters))
        end
      end

      def templated?
        @parameter_mode == 'tokens'
      end

      def interactive?
        !@interactive_mode.nil?
      end

      protected

      def find_in_hints(code_sample)
        return unless hints['samples']
        hints['samples'].each do |k, v|
          return v if k.downcase == code_sample.downcase
        end
        nil
      end

      def build_command(code_sample, sample_file)
        command = task_for(:run_sample)
        return nil if command.nil?

        command_params = { sample: code_sample, sample_file: sample_file }
        command_params.merge!(@parameters) unless @parameters.nil?
        Psychic::Util.replace_tokens(command, command_params)
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
          @cli.yes? "Would you like to #{file} to #{orig} before running the sample?"
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
