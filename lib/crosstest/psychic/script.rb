require 'crosstest/psychic/code_helper'

module Crosstest
  class Psychic
    class Script < CommandTemplate # rubocop:disable Metrics/ClassLength
      include CodeHelper
      include Crosstest::OutputHelper

      # @return [String] a name for the script
      attr_reader :name
      # @return [Pathname] the location of the script
      attr_reader :source_file
      # @return [Hash] options controlling how the script is executed
      attr_reader :opts
      # @return [Hash] params key/value pairs to bind to script input
      attr_accessor :params
      attr_accessor :env

      def initialize(psychic, name, source_file, opts = {})
        fail ArgumentError if psychic.nil?
        fail ArgumentError if name.nil?
        fail ArgumentError if source_file.nil?
        @name = name.to_s
        @source_file = Pathname(source_file)
        @opts ||= opts
        @env = opts[:env] || psychic.env
        @params = opts[:params] ||= psychic.parameters
        super psychic, ''
      end

      def basedir
        @psychic.basedir
      end

      def extname
        source_file.extname
      end

      def token_handler
        # Default token pattern/replacement (used by php-opencloud) should be configurable
        @token_handler ||= Tokens::RegexpTokenHandler.new(source, /'\{(\w+)\}'/, "'\\1'")
      end

      def execute(*extra_args)
        process_parameters if params
        command_params = { script: name, script_file: source_file }
        command_params.merge!(params) unless params.nil?
        super(command_params, *extra_args)
      end

      def to_s(verbose = false)
        build_string do
          status('Script Name', name)
          display_tokens
          status('Source File', formatted_file_name)
          display_source if verbose
        end
      end

      def to_path
        # So coercion to Pathname is possible
        source_file.to_s
      end

      def tokenized?
        opts[:parameter_mode] == 'tokens'
      end

      def interactive?
        psychic.interactive?
      end

      def process_parameters # rubocop
        if params.is_a? String
          self.params = YAML.load(Tokens.replace_tokens(params, env))
        end

        process_tokens if tokenized?
      end

      private

      # This will be moved to separate classes for different input strategies...
      def process_tokens
        backup_and_overwrite(absolute_source_file)
        template = File.read(absolute_source_file)
        # Default token pattern/replacement (used by php-opencloud) should be configurable
        token_handler = Tokens::RegexpTokenHandler.new(template, /'\{(\w+)\}'/, "'\\1'")
        confirm_or_update_parameters(token_handler.tokens)
        File.write(absolute_source_file, token_handler.render(params))
      end

      def build_command
        return @command if defined? @command

        script_factory = psychic.script_factory_manager.factories_for(self).last
        fail Crosstest::Psychic::ScriptNotRunnable, script if script_factory.nil?

        @command = script_factory.script(self)
        @command = @command.call if @command.respond_to? :call
        @command
      end

      def display_source
        return unless source?
        status 'Source Code'
        say highlighted_code
      end

      def display_tokens
        return status 'Tokens', '(None)' if !tokenized? || token_handler.tokens.empty?

        status 'Tokens'
        indent do
          token_handler.tokens.each do | token |
            say "- #{token}"
          end
        end
      end

      def formatted_file_name
        if source?
          Crosstest::Core::FileSystem.relativize(absolute_source_file, Dir.pwd)
        else
          colorize('<No script>', :red)
        end
      end

      def backup_and_overwrite(file)
        backup_file = "#{file}.bak"
        if File.exist? backup_file
          if should_restore?(backup_file, file)
            FileUtils.mv(backup_file, file)
          else
            fail 'Please clear out old backups before rerunning' if File.exist? backup_file
          end
        end
        FileUtils.cp(file, backup_file)
      end

      def should_restore?(file, orig, timing = :before)
        return true if [timing, 'always']. include? opts[:restore_mode]
        if interactive?
          cli.yes? "Would you like to #{file} to #{orig} before running the script?"
        end
      end

      def prompt(key)
        value = params[key]
        if value
          return value unless  opts[:interactive] == 'always'
          new_value = cli.ask "Please set a value for #{key} (or enter to confirm #{value.inspect}): "
          new_value.empty? ? value : new_value
        else
          cli.ask "Please set a value for #{key}: "
        end
      end

      def confirm_or_update_parameters(required_parameters)
        required_parameters.each do | key |
          params[key] = prompt(key)
        end if interactive?
      end
    end
  end
end
