module Psychic
  class Runner
    module CodeHelper
      class Highlighter
        def initialize(opts)
          require 'rouge'
          @lexer = Rouge::Lexer.find(opts[:language]) || Rouge::Lexer.guess_by_filename(opts[:filename])
          @formatter = opts[:formatter]
        rescue LoadError # rubocop:disable Lint/HandleExceptions
          # No highlighting support
        end

        def highlight(source)
          if defined?(Rouge)
            Rouge.highlight(source, @lexer, @formatter)
          else
            # No highlighting support
            source
          end
        end
      end

      class ReStructuredTextHelper
        def self.code_block(source, language)
          buffer = StringIO.new
          buffer.puts ".. code-block:: #{language}"
          indented_source = source.lines.map do|line|
            "  #{line}"
          end.join("\n")
          buffer.puts indented_source
          buffer.string
        end
      end
      class MarkdownHelper
        def self.code_block(source, language)
          buffer = StringIO.new
          buffer.puts # I've seen lots of rendering issues without a dividing newline
          buffer.puts "```#{language}"
          buffer.puts source
          buffer.puts '```'
          buffer.puts # Put a dividing newline after as well, to be safe...
          buffer.string
        end
      end

      def absolute_source_file
        return nil if source_file.nil?

        if basedir
          File.expand_path source_file, basedir
        else
          source_file
        end
      end

      def source
        File.read absolute_source_file
      end

      def source?
        !absolute_source_file.nil?
      end

      def language
        @language ||= detect_language
      end

      def detect_language
        File.extname(source_file)
      end

      def highlighted_code(formatter = 'terminal256')
        Highlighter.new(language: language, filename: absolute_source_file,
          formatter: formatter).highlight(source)
      end

      def code_block(source_code, language, opts = { format: :markdown })
        case opts[:format]
        when :rst
          ReStructuredTextHelper.code_block source_code, language
        when :markdown
          MarkdownHelper.code_block source_code, language
        else
          fail IllegalArgumentError, "Unknown format: #{format}"
        end
      end

      # TODO: Segmentation support...
      # def initialize(*args)
      #   @segmenter = Polytrix::Documentation::CodeSegmenter.new
      #   super
      # end

      # # Loses proper indentation on comments
      # def snippet_after(matcher)
      #   segments = @segmenter.segment(source)
      #   buffer = StringIO.new
      #   segment = segments.find do |s|
      #     doc_segment_content = s.first.join
      #     doc_segment_content.match matcher
      #   end
      #   buffer.print segment[1].join "\n" if segment # return code segment
      #   buffer.string
      # end

      # def snippet_between(before_matcher, after_matcher)
      #   segments = @segmenter.segment(source)
      #   start_segment = find_segment_index segments, before_matcher
      #   end_segment   = find_segment_index segments, after_matcher
      #   buffer = StringIO.new
      #   if start_segment && end_segment
      #     segments[start_segment...end_segment].each do |segment|
      #       buffer.puts @segmenter.comment(segment[0]) unless segment == segments[start_segment]
      #       buffer.puts segment[1].join
      #     end
      #   end
      #   buffer.puts "\n"
      #   buffer.string
      # end

      # private

      # def find_segment_index(segments, matcher)
      #   segments.find_index do |s|
      #     doc_segment_content = s.first.join
      #     doc_segment_content.match matcher
      #   end
      # end
    end
  end
end
