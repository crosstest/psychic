module Psychic
  class Runner
    module Cold
      RSpec.describe BundlerDetector do
        let(:shell) { Psychic::Shell.shell = double('shell') }
        subject { described_class.new(cwd: current_dir) }

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
          describe 'respond_to?' do
            it 'responds to bootstrap' do
              expect(subject.respond_to? :bootstrap).to be true
            end
            it 'does not respond to compile' do
              expect(subject.respond_to? :compile).to be false
            end
          end

          describe '#bootstrap' do
            it 'returns bundle install' do
              expect(subject.bootstrap).to eq('bundle install')
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
