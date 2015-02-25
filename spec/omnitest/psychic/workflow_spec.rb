require 'spec_helper'

module Omnitest
  class Psychic
    RSpec.describe Workflow do
      let(:psychic) { Psychic.new(cwd: current_dir) }

      before(:each) do
        write_file 'scripts/bootstrap.sh', ''
        write_file 'scripts/test.sh', ''
      end

      context 'with a block' do
        subject do
          described_class.new(psychic) do
            task :bootstrap
            task :test
          end
        end

        describe '#initialize' do
          it 'add commands by evaluating the block' do
            expect(subject.commands.size).to eq(2)
            expect(subject.commands).to all(be_an_instance_of Task)
          end
        end

        describe 'command' do
          it 'creates a combined script that runs each command' do
            expect(subject.command).to eq("./scripts/bootstrap.sh\n./scripts/test.sh\n")
          end
        end
      end

      context 'without a block' do
        describe '#initialize' do
          subject { described_class.new(psychic) }

          it 'creates a Workflow with no commands' do
            expect(subject.commands).to be_empty
          end
        end
      end
    end
  end
end
