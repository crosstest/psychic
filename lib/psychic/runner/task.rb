module Psychic
  class Runner
    class Task < Struct.new(:name, :command, :priority)
    end
  end
end
