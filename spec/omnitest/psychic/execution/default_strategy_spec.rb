require 'spec_helper'

RSpec.shared_examples 'replaces tokens' do
  let(:script) { Omnitest::Psychic.new(cwd: current_dir).script('sample.rb') }
  let(:subject) { described_class.new(script) }

  describe '#execute' do
    it 'replaces the token with an empty value the param is not set' do
      expect(subject.execute.stdout.strip).to be_empty
    end

    it 'replaces the token with the value of the param' do
      script.params['token'] = 'foo'
      expect(subject.execute.stdout).to include 'foo'
    end
  end
end
