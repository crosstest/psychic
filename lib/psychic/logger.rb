require 'logger'

module Psychic
  module Logger
    def logger
      @logger ||= new_logger
    end

    def new_logger(_io = $stdout, _level = :debug)
      ::Logger.new(STDOUT)
    end

    def log_level=(level)
      logger.level = level
    end
  end
end
