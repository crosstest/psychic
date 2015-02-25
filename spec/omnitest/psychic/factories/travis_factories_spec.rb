module Omnitest
  class Psychic
    module Factories
      RSpec.describe TravisTaskFactory do
        let(:psychic) { Psychic.new(cwd: current_dir) }
        let(:shell) { double('shell') }
        subject do
          psychic.shell = shell
          described_class.new(psychic, cwd: current_dir)
        end

        shared_context 'without .travis.yml' do
        end

        shared_context 'with .travis.yml' do
          before(:each) do
            ENV['BUNDLE_GEMFILE'] = nil
            write_file '.travis.yml', ''
          end
        end

        shared_examples 'does not use Travis' do
          describe 'active?' do
            it 'returns false' do
              expect(subject.active?).to be false
            end
          end
        end

        shared_examples 'uses Travis' do
          describe 'known_task?' do
            it 'is true for bootstrap' do
              expect(subject.known_task? :bootstrap).to be true
            end
            it 'is true for test' do
              expect(subject.known_task? :test).to be true
            end
            it 'is false for lint' do
              expect(subject.known_task? :lint).to be false
            end
          end

          # TODO: Do we want to return the travis command itself, or the result of `travis run -p`?

          describe '#bootstrap' do
            it 'returns travis run install' do
              expect(shell).to receive(:execute).with('travis run --print --skip-version-check install', cwd: current_dir).and_return(
                Fabricate(:execution_result, stdout: 'script from travis')
              )
              expect(subject.task(:bootstrap)).to eq('script from travis')
            end
          end

          describe '#test' do
            it 'returns travis run script' do
              expect(shell).to receive(:execute).with('travis run --print --skip-version-check script', cwd: current_dir).and_return(
                Fabricate(:execution_result, stdout: 'script from travis')
              )
              expect(subject.task(:test)).to eq('script from travis')
            end
          end
        end

        context 'with .travis.yml' do
          include_context 'with .travis.yml' do
            include_examples 'uses Travis'
          end
        end

        context 'without .travis.yml' do
          include_context 'without .travis.yml' do
            include_examples 'does not use Travis'
          end
        end
      end
    end
  end
end
