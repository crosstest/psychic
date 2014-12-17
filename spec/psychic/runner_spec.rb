require 'spec_helper'

module Psychic
  RSpec.describe Runner do
    subject { described_class.new(cwd: current_dir) }
    context 'when psychic.yml exists' do
      let(:hints) do
        {
          'tasks' =>
          {
            'bootstrap' => 'foo',
            'compile'   => 'bar',
            'execute'   => 'baz'
          }
        }
      end

      before(:each) do
        write_file 'psychic.yml', YAML.dump(hints)
      end

      describe 'initialize' do
        it 'should create a HotRunner for the specified directory' do
          expect(subject.hot_runner).to be_an_instance_of(Psychic::Runner::HotRunner)
          expect(subject.cwd).to eq(current_dir)
        end
      end
    end

    context 'when scripts/* exist' do
      before(:each) do
        write_file 'scripts/bootstrap.sh', ''
        write_file 'scripts/foo.sh', ''
      end

      describe 'initialize' do
        it 'should create a cold runner for ShellScriptRunner' do
          expect(subject.cold_runners).to include(
            an_instance_of(Psychic::Runner::Cold::ShellScriptRunner)
          )
        end
      end
    end
  end
end
