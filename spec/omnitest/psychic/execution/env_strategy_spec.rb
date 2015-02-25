require 'spec_helper'

module Omnitest
  class Psychic
    module Execution
      RSpec.describe EnvStrategy do
        before(:each) do
          write_file 'sample.rb', <<-eos
          puts ENV['token']
          eos
        end

        include_examples 'replaces tokens'
      end
    end
  end
end
