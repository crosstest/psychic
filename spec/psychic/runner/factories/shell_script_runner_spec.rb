module Psychic
  class Runner
    module Factories
      RSpec.describe ShellScriptTaskFactory do
        let(:shell) { Psychic::Shell.shell = double('shell') }
        subject { described_class.new(cwd: current_dir) }

        shared_context 'with scripts/*.sh files' do
          before(:each) do
            write_file 'scripts/bootstrap.sh', ''
            write_file 'scripts/compile.sh', ''
            write_file 'scripts/foo.ps1', ''
          end
        end

        shared_context 'with scripts/* (no extension) files' do
          before(:each) do
            write_file 'scripts/bootstrap', ''
            write_file 'scripts/compile', ''
            write_file 'scripts/.foo', ''
          end
        end

        describe 'known_task?' do
          shared_examples 'detects matching scripts' do
            it 'returns true if a matching script exists' do
              expect(subject.known_task? :bootstrap).to be true
              expect(subject.known_task? :compile).to be true
            end
            it 'returns false if a matching script does not exists' do
              expect(subject.known_task? :foo).to be false
              expect(subject.known_task? :bar).to be false
            end
          end

          context 'with scripts/*.sh files' do
            include_context 'with scripts/*.sh files' do
              include_examples 'detects matching scripts'
            end
          end

          context 'with scripts/* (no extension) files' do
            include_context 'with scripts/* (no extension) files' do
              include_examples 'detects matching scripts'
            end
          end
        end

        describe '#task_for' do
          context 'matching a task' do
            context 'with scripts/*.sh files' do
              include_context 'with scripts/*.sh files' do
                it 'returns the script command' do
                  expect(subject.task_for :bootstrap).to eq('./scripts/bootstrap.sh')
                end
              end
            end

            context 'with scripts/* (no extension) files' do
              include_context 'with scripts/* (no extension) files' do
                it 'executes the script command' do
                  expect(subject.task_for :bootstrap).to eq('./scripts/bootstrap')
                end
              end
            end
          end

          context 'not matching a task' do
            it 'raises an error' do
              # Use foo to ensure it doesn't match ps1 or hidden (. prefixed) files
              expect(subject.task_for :foo).to be nil
            end
          end
        end
      end
    end
  end
end
