require 'spec_helper'

module Omnitest
  class Psychic
    module Execution
      RSpec.describe FlagStrategy do
        before(:each) do
          write_file 'sample.rb', <<-eos
          require 'optparse'

          options = {}
          OptionParser.new do |opts|
            opts.on("--token=TOKEN", "The token") do |v|
              options[:token] = v
            end
          end.parse!

          puts options[:token]
          eos
        end

        include_examples 'replaces tokens'
      end
    end
  end
end
