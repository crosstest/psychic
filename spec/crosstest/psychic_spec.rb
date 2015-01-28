require 'spec_helper'

module Crosstest
  RSpec.describe Psychic do
    subject { described_class.new(cwd: current_dir) }
    context 'when psychic.yml exists' do
      let(:hints) do
        {
          'tasks' =>
          {
            'bootstrap' => 'foo',
            'compile'   => 'bar',
            'execute'   => 'baz'
          }
        }
      end

      before(:each) do
        write_file 'psychic.yml', YAML.dump(hints)
      end

      describe 'initialize' do
        it 'should create a HotReadTaskFactory for the specified directory' do
          hot_task_factory = subject.task_factory_manager.active? Psychic::Factories::HotReadTaskFactory
          expect(hot_task_factory).to_not be nil
          expect(hot_task_factory.cwd).to eq(current_dir)
        end
      end

      describe '#execute' do
        it 'can accept a string' do
          execution_result = subject.execute('echo', 'hi')
          expect(execution_result.stdout).to match(/\Ahi\Z/)
        end
      end
    end

    context 'when scripts/* exist' do
      before(:each) do
        write_file 'scripts/bootstrap.sh', ''
        write_file 'scripts/foo.sh', 'echo "hi"'
        filesystem_permissions '0744', 'scripts/foo.sh'
        write_file 'scripts/foo.ps1', 'Write-Host "hi"'
      end

      describe 'initialize' do
        it 'should create a ShellTaskFactory' do
          shell_task_factory = subject.task_factory_manager.active? Psychic::Factories::ShellTaskFactory
          expect(shell_task_factory).to_not be nil
          expect(shell_task_factory.cwd).to eq(current_dir)
        end
      end

      describe '#execute_task' do
        it 'captures output' do
          execution_result = subject.execute_task('foo')
          expect(execution_result.stdout).to include('hi')
        end
      end
    end

    context 'running scripts' do
      describe '#run_script' do
        before(:each) do
          write_file 'samples/hi.rb', 'puts "hi"'
        end

        shared_examples 'executes' do
          it 'captures output' do
            execution_result = subject.run_script(script)
            expect(execution_result.stdout).to include('hi')
          end
        end

        context 'by path' do
          let(:script) { 'samples/hi.rb' }
          include_examples 'executes'
        end

        context 'by alias' do
          let(:script) { 'hi' }
          include_examples 'executes'
        end

        context 'by hint' do
          let(:hints) do
            ''"
            scripts:
              custom: samples/hi.rb
            "''
          end
          before(:each) { write_file 'psychic.yaml', hints }

          let(:script) { 'custom' }
          include_examples 'executes'
        end
      end
    end
  end
end
