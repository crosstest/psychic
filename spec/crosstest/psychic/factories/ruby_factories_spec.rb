module Crosstest
  class Psychic
    module Factories
      RSpec.describe BundlerTaskFactory do
        let(:runner) { double('runner') }
        let(:shell) { Crosstest::Shell.shell = double('shell') }
        subject { described_class.new(runner, cwd: current_dir) }

        shared_context 'without bundler' do
          before(:each) do
            ENV['BUNDLE_GEMFILE'] = nil
          end
        end

        shared_context 'with Gemfile' do
          before(:each) do
            ENV['BUNDLE_GEMFILE'] = nil
            write_file 'Gemfile', ''
          end
        end

        shared_context 'with .bundle/config' do
          before(:each) do
            ENV['BUNDLE_GEMFILE'] = nil
            write_file '.bundle/config', <<-eos
---
BUNDLE_GEMFILE: "../../Gemfile"
eos
          end
        end

        shared_context 'with BUNDLE_GEMFILE environment variable' do
          around(:each) do | example |
            ENV['BUNDLE_GEMFILE'] = 'Gemfile'
            example.run
            ENV['BUNDLE_GEMFILE'] = nil
          end
        end

        shared_examples 'does not use bundler' do
          describe 'active?' do
            it 'returns false' do
              expect(subject.active?).to be false
            end
          end
        end

        shared_examples 'uses bundler' do
          describe 'known_task?' do
            it 'is true for bootstrap' do
              expect(subject.known_task? :bootstrap).to be true
            end
            it 'is false for compile' do
              expect(subject.known_task? :compile).to be false
            end
          end

          describe '#bootstrap' do
            it 'returns bundle install' do
              expect(subject.find_task(:bootstrap)).to eq('bundle install')
            end
          end
        end

        context 'with Gemfile' do
          include_context 'with Gemfile' do
            include_examples 'uses bundler'
          end
        end

        context 'with .bundle/config' do
          include_context 'with .bundle/config' do
            include_examples 'uses bundler'
          end
        end

        context 'with BUNDLE_GEMFILE environment variable' do
          include_context 'with BUNDLE_GEMFILE environment variable' do
            include_examples 'uses bundler'
          end
        end

        context 'without bundler' do
          include_context 'without bundler' do
            include_examples 'does not use bundler'
          end
        end
      end
    end
  end
end
