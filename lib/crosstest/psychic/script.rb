require 'crosstest/psychic/code_helper'

module Crosstest
  class Psychic
    class Script # rubocop:disable Metrics/ClassLength
      include CodeHelper
      include Crosstest::OutputHelper

      attr_reader :psychic

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
        @psychic = psychic
      end

      def basedir
        @psychic.basedir
      end

      def extname
        source_file.extname
      end

      def command
        execution_strategy.command
      end

      def execute(*extra_args)
        execution_strategy.execute *extra_args
      end

      def tokens
        return [] unless detection_strategy.respond_to? :tokens
        @tokens ||= detection_strategy.tokens
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

      def detection_strategy
        @detection_strategy ||= create_detection_strategy
      end

      def execution_strategy
        @execution_strategy ||= create_execution_strategy
      end

      def interactive?
        @psychic.interactive?
      end

      private

      def display_source
        return unless source?
        status 'Source Code'
        say highlighted_code
      end

      def display_tokens
        return status 'Tokens', '(None)' if tokens.empty?

        status 'Tokens'
        indent do
          tokens.each do | token |
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

      def create_execution_strategy
        strategy = opts[:execution_strategy]
        case strategy
        when nil
          Execution::DefaultStrategy.new self
        when 'tokens'
          Execution::TokenStrategy.new self
        when 'environment_variables'
          Execution::EnvStrategy.new self
        when 'flags'
          Execution::FlagStrategy.new self
        else
          # TODO: Need support for custom commands with positional args
          fail "Unknown binding strategy #{strategy}"
        end
      end

      def create_detection_strategy
        strategy = opts[:detection_strategy] || opts[:execution_strategy]
        case strategy
        when nil
          nil
        when 'tokens'
          Tokens::RegexpTokenHandler.new(source, /'\{(\w+)\}'/, "'\\1'")
        else
          # TODO: Need support for detecting tokens from comments, help commands, etc.
          fail "Unknown token detection strategy #{strategy}"
        end
      end
    end
  end
end
