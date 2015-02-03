module Crosstest
  class Psychic
    module Factories
      RSpec.describe JavaFactory do
        let(:psychic) { Psychic.new(cwd: current_dir) }
        let(:shell) { Crosstest::Shell.shell = double('shell') }
        subject { described_class.new(psychic, cwd: current_dir) }

        before(:each) do
          write_file('src/main/java/HelloWorld.java', '')
          write_file('src/main/java/org/mycompany/FQ.java', '')
          write_file('src/test/java/org/mycompany/FQTest.java', '')
        end

        describe '#script' do
          let(:hello_world) { psychic.script('hello world') }
          let(:fq) { psychic.script('fq') }
          let(:fqtest) { psychic.script('fqtest') }

          it 'converts files without a package to a classname only' do
            expect(subject.script hello_world).to eq('java -classpath build/libs/* HelloWorld')
          end

          it 'converts files with a package to a fully qualified name' do
            expect(subject.script fq).to eq('java -classpath build/libs/* org.mycompany.FQ')
          end

          it 'converts files with a package to a fully qualified name' do
            expect(subject.script fqtest).to eq('java -classpath build/libs/* org.mycompany.FQTest')
          end
        end
      end
    end
  end
end
