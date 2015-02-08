require 'spec_helper'

module Crosstest
  class Psychic
    module Execution
      RSpec.describe TokenStrategy do
        before(:each) do
          write_file 'sample.rb', <<-eos
          puts '{token}'
          eos
        end

        let(:script) { Psychic.new(cwd: current_dir).script('sample') }
        let(:subject) { described_class.new(script) }

        include_examples 'replaces tokens'

        describe '#execute' do
          it 'does not permanently alter the file' do
            expect { subject.execute }.to_not change { File.read("#{current_dir}/sample.rb") }
          end
        end
      end
    end
  end
end
