module Psychic
  class Runner
    module Cold
      RSpec.describe ShellScriptRunner do
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

        describe 'respond_to?' do
          shared_examples 'detects matching scripts' do
            it 'returns true if a matching script exists' do
              expect(subject.respond_to? :bootstrap).to be true
              expect(subject.respond_to? :compile).to be true
            end
            it 'returns false if a matching script does not exists' do
              expect(subject.respond_to? :foo).to be false
              expect(subject.respond_to? :bar).to be false
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

        describe '#method_missing' do
          context 'matching a task' do
            context 'with scripts/*.sh files' do
              include_context 'with scripts/*.sh files' do
                it 'executes the script command' do
                  expect(shell).to receive(:execute).with('./scripts/bootstrap.sh', cwd: current_dir)
                  subject.bootstrap
                end
              end
            end

            context 'with scripts/* (no extension) files' do
              include_context 'with scripts/* (no extension) files' do
                it 'executes the script command' do
                  expect(shell).to receive(:execute).with('./scripts/bootstrap', cwd: current_dir)
                  subject.bootstrap
                end
              end
            end
          end

          context 'not matching a task' do
            it 'raises an error' do
              # Use foo to ensure it doesn't match ps1 or hidden (. prefixed) files
              expect { subject.foo }.to raise_error(NoMethodError)
            end
          end
        end
      end
    end
  end
end
