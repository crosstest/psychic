require 'spec_helper'

module Crosstest
  class Psychic
    class FakeRubyFactory < ScriptFactory
      runs '**.fake_rb'
      runs '**.fake_erb'
    end

    class FakeJavaScriptFactory < ScriptFactory
      runs '**.fake_js'
    end

    RSpec.describe ScriptFactoryManager do
      let(:psychic) { Psychic.new(cwd: current_dir) }
      let(:opts) do
        {}
      end
      let(:subject) do
        described_class.new psychic, opts
      end

      before(:each) do
        described_class.register_factory(FakeRubyFactory)
        described_class.register_factory(FakeJavaScriptFactory)
      end

      def fake_script(name)
        write_file name, ''
        psychic.find_script name
      end

      describe '#initialize' do
        it 'creates instances of registered factories' do
          expect(subject.factories).to include(
            an_instance_of FakeRubyFactory
          )
        end
      end

      describe '#factories_for' do
        it 'returns nil if no factories can run the script' do
          expect(subject.factories_for fake_script('foo.asdf')).to be_empty
        end

        it 'returns the factories that can run the script' do
          expect(subject.factories_for fake_script('foo.fake_rb')).to include(
            an_instance_of FakeRubyFactory
          )
          expect(subject.factories_for fake_script('foo.fake_js')).to include(
            an_instance_of FakeJavaScriptFactory
          )
        end
      end
    end
  end
end
