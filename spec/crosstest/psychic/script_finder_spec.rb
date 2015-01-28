require 'spec_helper'

module Crosstest
  class Psychic
    RSpec.describe ScriptFinder do
      context 'without hints' do
        describe '#known_scripts' do
          it 'returns an empty list' do
            expect(subject.known_scripts).to be_empty
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

        it 'returns the scripts from the hints' do
          scripts = subject.known_scripts
          expect(scripts.size).to eq(2)
          expect(scripts[0].name).to eq('foo')
          expect(scripts[0].source_file.to_s).to eq('/path/to/foo.c')
          expect(scripts[1].name).to eq('bar')
          expect(scripts[1].source_file.to_s).to eq('/path/to/bar.rb')
        end
      end
    end
  end
end
