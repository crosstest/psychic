require 'spec_helper'

module Crosstest
  class Psychic
    RSpec.describe Script do
      before(:each) do
        write_file 'sample.rb', <<-eos
        puts 'hello'
        puts '{basic_token}'
        puts '{{mustache_token}}'
        puts ENV['ENV_VAR']
        # --flag
        opts = {}
        # Pretend we parsed opts
        puts opts[:flag]
        eos
      end

      subject { Psychic.new(cwd: current_dir).script('sample') }

      describe '#tokens' do
        it 'is empty if the there is no detection_strategy' do
          subject.opts[:detection_strategy] = nil
          expect(subject.tokens).to be_empty
        end

        it 'finds the basic_token if the execution strategy is tokens' do
          subject.opts[:detection_strategy] = 'tokens'
          expect(subject.tokens).to eq(['basic_token'])
        end
      end

      describe '#execution_strategy' do
        it 'is a DefaultStrategy if the mode is not set' do
          expect(subject.execution_strategy).to be_an_instance_of Execution::DefaultStrategy
        end

        it 'is an EnvStrategy if the mode is env' do
          subject.opts[:execution_strategy] = 'environment_variables'
          expect(subject.execution_strategy).to be_an_instance_of Execution::EnvStrategy
        end

        it 'is a FlagStrategy if the mode is flags' do
          subject.opts[:execution_strategy] = 'flags'
          expect(subject.execution_strategy).to be_an_instance_of Execution::FlagStrategy
        end

        it 'is a TokenStrategy if the mode is tokens' do
          subject.opts[:execution_strategy] = 'tokens'
          expect(subject.execution_strategy).to be_an_instance_of Execution::TokenStrategy
        end
      end
    end
  end
end
