module Psychic
  class Runner
    class Task < Strict.new(:name, :command)
      def command
        fail NotImplementedError, 'Subclasses must implement command'
      end

      def execute(opts)
        puts "Executing: #{command}" if opts[:verbose]
        executor.execute(command, opts)
      end
    end
  end
end
