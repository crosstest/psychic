module Psychic
  class Runner
    class HotRunner
      include BaseRunner
      def initialize(opts = {})
        hints = opts.delete :hints
        super
        @hints = Psychic::Util.stringified_hash(hints || load_hints || {})
        @tasks = @hints['tasks'] || {}
        @known_tasks = @tasks.keys
      end

      def [](task_name)
        @tasks[task_name]
      end

      private

      def load_hints
        hints_file = Dir["#{@cwd}/psychic-hints.{yaml,yml}"].first
        YAML.load(File.read(hints_file)) unless hints_file.nil?
      end
    end
  end
end
