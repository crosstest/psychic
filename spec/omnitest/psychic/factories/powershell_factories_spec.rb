module Omnitest
  class Psychic
    module Factories
      RSpec.describe PowerShellTaskFactory do
        let(:psychic) { Psychic.new(cwd: current_dir) }
        let(:shell) { Omnitest::Shell.shell = double('shell') }
        subject { described_class.new(psychic, cwd: current_dir) }

        shared_context 'with scripts/*.ps1 files' do
          before(:each) do
            write_file 'scripts/bootstrap.ps1', ''
            write_file 'scripts/compile.ps1', ''
            write_file 'scripts/foo.sh', ''
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

          context 'with scripts/*.ps1 files' do
            include_context 'with scripts/*.ps1 files' do
              include_examples 'detects matching scripts'
            end
          end
        end

        describe '#task' do
          context 'matching a task' do
            context 'with scripts/*.ps1 files' do
              include_context 'with scripts/*.ps1 files' do
                it 'returns the script command' do
                  expect(subject.task :bootstrap).to eq(
                    'PowerShell -NoProfile -ExecutionPolicy Bypass -File "scripts/bootstrap.ps1"'
                  )
                end
              end
            end
          end

          context 'not matching a task' do
            it 'raises an error' do
              # Use foo to ensure it doesn't match ps1 or hidden (. prefixed) files
              expect(subject.task :foo).to be nil
            end
          end
        end
      end
    end
  end
end
