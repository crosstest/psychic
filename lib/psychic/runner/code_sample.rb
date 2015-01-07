require 'psychic/runner/code_helper'

module Psychic
  class Runner
    class CodeSample < Struct.new(:name, :source_file, :basedir)
      include CodeHelper
      include Psychic::OutputHelper
      # property :name
      # property :basedir
      # property :source_file

      def token_handler
        # Default token pattern/replacement (used by php-opencloud) should be configurable
        @token_handler ||= RegexpTokenHandler.new(source, /'\{(\w+)\}'/, "'\\1'")
      end

      def command(runner)
        command = runner.task_for(:run_sample)
        # FIXME: Shouldn't this be relative to runner's cwd?
        # command ||= Psychic::Util.relativize(source_file, runner.cwd)
        command ||= "./#{source_file}"

        command_params = { sample: name, sample_file: source_file }
        command_params.merge!(@parameters) unless @parameters.nil?
        Psychic::Util.replace_tokens(command, command_params)
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

      private

      def display_source
        return unless source?
        status 'Source Code'
        say highlighted_code
      end

      def display_tokens
        return status 'Tokens', '(None)' if token_handler.tokens.empty?

        status 'Tokens'
        indent do
          token_handler.tokens.each do | token |
            say "- #{token}"
          end
        end
      end

      def formatted_file_name
        if source?
          Psychic::Util.relativize(absolute_source_file, Dir.pwd)
        else
          colorize('<No code sample>', :red)
        end
      end
    end
  end
end
