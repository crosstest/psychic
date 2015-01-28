require 'crosstest/psychic/code_helper'

module Crosstest
  class Psychic
    class CodeSample < Core::Dash
      include CodeHelper
      include Crosstest::OutputHelper
      extend Forwardable
      def_delegators :source_file, :extname

      required_field :name, String
      required_field :source_file, Pathname
      field :basedir, Pathname
      field :opts, Hash, default: {}

      def inititalize(*args)
        super
        @opts ||= {}
      end

      def token_handler
        # Default token pattern/replacement (used by php-opencloud) should be configurable
        @token_handler ||= Tokens::RegexpTokenHandler.new(source, /'\{(\w+)\}'/, "'\\1'")
      end

      def command(psychic)
        # FIXME: Just psychic.command_for_sample(...) ?
        command = psychic.command_for_sample(self)
        # FIXME: Shouldn't this be relative to psychic's cwd?
        # command ||= Crosstest::Core::FileSystem.relativize(source_file, psychic.cwd)
        # command ||= "./#{source_file}"
        command = command.call if command.respond_to? :call

        command_params = { sample: name, sample_file: source_file }
        command_params.merge!(@parameters) unless @parameters.nil?
        Tokens.replace_tokens(command, command_params)
      end

      def to_s(verbose = false)
        build_string do
          status('Sample Name', name)
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

      private

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
          colorize('<No code sample>', :red)
        end
      end
    end
  end
end
