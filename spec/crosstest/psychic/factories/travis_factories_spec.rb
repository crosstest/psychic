module Crosstest
  class Psychic
    module Factories
      RSpec.describe TravisTaskFactory do
        let(:psychic) { double('psychic') }
        let(:shell) { Crosstest::Shell.shell = double('shell') }
        subject { described_class.new(psychic, cwd: current_dir) }

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
              expect(subject.find_task(:bootstrap)).to eq('travis run --skip-version-check install')
            end
          end

          describe '#test' do
            it 'returns travis run script' do
              expect(subject.find_task(:test)).to eq('travis run --skip-version-check script')
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
