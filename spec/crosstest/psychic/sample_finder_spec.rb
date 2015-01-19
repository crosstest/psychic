require 'spec_helper'

module Crosstest
  class Psychic
    RSpec.describe SampleFinder do
      context 'without hints' do
        describe '#known_samples' do
          it 'returns an empty list' do
            expect(subject.known_samples).to be_empty
          end
        end
      end

      context 'with hints' do
        let(:hints) do
          {
            'foo' => '/path/to/foo.c',
            'bar' => '/path/to/bar.rb'
          }
        end
        subject { described_class.new(Dir.pwd, hints) }

        it 'returns the samples from the hints' do
          samples = subject.known_samples
          expect(samples.size).to eq(2)
          expect(samples[0].name).to eq('foo')
          expect(samples[0].source_file).to eq('/path/to/foo.c')
          expect(samples[1].name).to eq('bar')
          expect(samples[1].source_file).to eq('/path/to/bar.rb')
        end
      end
    end
  end
end
