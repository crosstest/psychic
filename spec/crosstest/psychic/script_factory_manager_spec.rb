require 'spec_helper'

module Crosstest
  class Psychic
    class FakeRubyFactory < ScriptFactory
      runs_extension 'fake_rb'
      runs_extension 'fake_erb'
    end

    class FakeJavaScriptFactory < ScriptFactory
      runs_extension 'fake_js'
    end

    RSpec.describe ScriptFactoryManager do
      let(:runner) { instance_double(Psychic) }
      let(:opts) do
        {}
      end
      let(:subject) do
        described_class.new runner, opts
      end

      before(:each) do
        described_class.register_factory(FakeRubyFactory)
        described_class.register_factory(FakeJavaScriptFactory)
      end

      describe '#initialize' do
        it 'creates instances of registered factories' do
          expect(subject.factories).to include(
            an_instance_of FakeRubyFactory
          )
        end
      end

      describe '#find_by_ext' do
        it 'returns nil if no engines can run the extension' do
          expect(subject.find_by_ext 'foo').to be nil
        end

        it 'returns the engine for a given extension' do
          expect(subject.find_by_ext 'fake_rb').to be_an_instance_of(FakeRubyFactory)
          expect(subject.find_by_ext 'fake_js').to be_an_instance_of(FakeJavaScriptFactory)
        end
      end
    end
  end
end
