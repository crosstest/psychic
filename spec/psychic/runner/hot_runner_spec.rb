module Psychic
  class Runner
    RSpec.describe HotRunner do
      let(:task_map) do
        {
          'bootstrap' => 'foo',
          'compile'   => 'bar',
          'execute'   => 'baz'
        }
      end
      let(:shell) { Psychic::Shell.shell = double('shell') }
      subject { described_class.new(cwd: current_dir, hints: task_map) }

      shared_examples 'runs tasks' do
        describe 'respond_to?' do
          it 'returns true for task ids' do
            task_map.each_key do |key|
              expect(subject.respond_to? key).to be true
            end
          end

          it 'returns false for anything else' do
            expect(subject.respond_to? 'max').to be false
          end
        end

        describe '#method_missing' do
          context 'matching a task' do
            it 'executes the task command' do
              expect(shell).to receive(:execute).with('foo', cwd: current_dir)
              subject.bootstrap
            end
          end

          context 'not matching a task' do
            it 'raises an error' do
              expect { subject.spin_around }.to raise_error(NoMethodError)
            end
          end
        end
      end

      context 'task map stored in psychic-hints.yml' do
        let(:hints) do
          { 'tasks' => task_map }
        end
        before(:each) do
          write_file 'psychic-hints.yml', YAML.dump(hints)
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
