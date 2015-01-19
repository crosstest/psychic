module Crosstest
  class Psychic
    RSpec.describe HotReadTaskFactory do
      let(:task_map) do
        {
          'bootstrap' => 'foo',
          'compile'   => 'bar',
          'execute'   => 'baz'
        }
      end
      let(:shell) { Crosstest::Shell.shell = double('shell') }
      subject { described_class.new(cwd: current_dir, hints: task_map) }

      shared_examples 'runs tasks' do
        describe 'known_task?' do
          it 'returns true for task ids' do
            task_map.each_key do |key|
              expect(subject.known_task? key).to be true
            end
          end

          it 'returns false for anything else' do
            expect(subject.known_task? 'max').to be false
          end
        end

        describe '#command_for_task' do
          context 'matching a task' do
            it 'builds the task command' do
              expect(subject.command_for_task(:bootstrap)).to eq('foo')
            end
          end

          context 'not matching a task' do
            it 'raises an error' do
              expect { subject.spin_around }.to raise_error(NoMethodError)
            end
          end
        end
      end

      context 'task map stored in psychic.yml' do
        let(:hints) do
          { 'tasks' => task_map }
        end
        before(:each) do
          write_file 'psychic.yml', YAML.dump(hints)
        end
        subject { described_class.new(cwd: current_dir) }
        include_examples 'runs tasks'
      end

      context 'hints passed as a parameter' do
        let(:hints) do
          { 'tasks' => task_map }
        end
        subject { described_class.new(cwd: current_dir, hints: hints) }
        include_examples 'runs tasks'
      end
    end
  end
end
