require 'crosstest/psychic/code2doc/code_segmenter'
require 'rouge'

module Crosstest
  class Psychic
    module Code2Doc
      module CodeHelper
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
            buffer.puts "```#{language}"
            buffer.puts source
            buffer.puts '```'
            buffer.string
          end
        end

        def source
          File.read absolute_source_file
        end

        def source?
          !absolute_source_file.nil?
        end

        def highlighted_code(formatter = 'terminal256')
          language, _comment_style = Code2Doc::CommentStyles.infer source_file.extname
          highlight(source, language: language, filename: absolute_source_file, formatter: formatter)
        end

        def code_block(source_code, language, opts = { format: :markdown })
          case opts[:format].to_sym
          when :rst
            ReStructuredTextHelper.code_block source_code, language
          when :md, :markdown
            MarkdownHelper.code_block source_code, language
          when :raw
            source_code
          else
            fail ArgumentError, "Unknown format: #{opts[:format]}"
          end
        end

        # Loses proper indentation on comments
        def snippet_after(matcher)
          segments = segmenter.segment(source)
          buffer = StringIO.new
          segment = segments.find do |s|
            doc_segment_content = s.first.join
            doc_segment_content.match matcher
          end
          buffer.print segment[1].join "\n" if segment # return code segment
          buffer.string
        end

        def snippet_between(before_matcher, after_matcher)
          segments = segmenter.segment(source)
          start_segment = find_segment_index segments, before_matcher
          end_segment   = find_segment_index segments, after_matcher
          buffer = StringIO.new
          if start_segment && end_segment
            segments[start_segment...end_segment].each do |segment|
              buffer.puts @segmenter.comment(segment[0]) unless segment == segments[start_segment]
              buffer.puts segment[1].join
            end
          end
          buffer.string
        end

        def code2doc(options = { format: :markdown })
          source_code = File.read(absolute_source_file)
          segmenter_language = infer_language(source_file)

          buffer = StringIO.new
          segmenter_options = {
            language: segmenter_language
          }
          segmenter = Crosstest::Psychic::Code2Doc::CodeSegmenter.new(segmenter_options)
          segments = segmenter.segment source_code
          segments.each do |comment, code|
            comment = comment.join("\n")
            code = code.join("\n")
            code = code_block(code, segmenter_language, options) unless code.empty?
            next if comment.empty? && code.empty?
            code = "\n#{code}\n" if !comment.empty? && !code.empty? # Markdown needs separation
            buffer.puts [comment, code].join("\n")
          end
          buffer.string
        end

        def infer_language(file)
          language, comment_style = Psychic::Code2Doc::CommentStyles.infer File.extname(file)
          segmenter_language = comment_style[:language] || language
        end

        private

        def segmenter
          @segmenter ||= Code2Doc::CodeSegmenter.new
        end

        def find_segment_index(segments, matcher)
          segments.find_index do |s|
            doc_segment_content = s.first.join
            doc_segment_content.match matcher
          end
        end
      end
    end
  end
end
