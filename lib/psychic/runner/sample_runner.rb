module Psychic
  class Runner
    module SampleRunner
      def run_sample(code_sample, *args)
        sample_file = Psychic::Util.find_file_by_alias(code_sample, cwd)
        process_template(sample_file) if templated?
        command = command_for_task('run_sample')
        if command
          variables = { sample: code_sample, sample_file: sample_file }
          command = Psychic::Util.replace_tokens(command, variables)
          execute(command, *args)
        else
          run_sample_file(sample_file)
        end
      end

      def run_sample_file(sample_file, *args)
        execute("./#{sample_file}", *args) # Assuming Bash, but should detect Windows and use PowerShell
      end

      def process_template(sample_file)
        absolute_sample_file = File.expand_path(sample_file, cwd)
        template = File.read(absolute_sample_file)
        # Default token pattern/replacement (used by php-opencloud) should be configurable
        content = Psychic::Util.replace_tokens(template, variables, /'\{(\w+)\}'/, "'\\1'")

        # Backup and overwrite
        backup_file = "#{absolute_sample_file}.bak"
        fail 'Please clear out old backups before rerunning' if File.exist? backup_file
        FileUtils.cp(absolute_sample_file, backup_file)
        File.write(absolute_sample_file, content)
      end

      def templated?
        # Probably not the best way to turn this on/off
        true unless variables.nil?
      end

      def variables
        # ... or
        variables_file = Dir["#{cwd}/psychic-variables.{yaml,yml}"].first
        return nil unless variables_file
        environment_variables = ENV.to_hash
        environment_variables.merge!(@opts[:env]) if @opts[:env]
        variables = Psychic::Util.replace_tokens(File.read(variables_file), environment_variables)
        YAML.load(variables)
      end
    end
  end
end
