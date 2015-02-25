require 'spec_helper'

module Omnitest
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
        it 'can accept additional arguments' do
          if subject.os_family == :windows
            cmd = 'Write-Host'
          else
            cmd = 'echo'
          end
          execution_result = subject.execute(cmd, 'hi', 'max')
          expect(execution_result.stdout.strip).to eq('hi max')
        end

        it 'can accept a hash of shell opts' do
          if subject.os_family == :windows
            cmd = 'Write-Host $env:FOO'
          else
            cmd = 'echo $FOO'
          end

          execution_result = subject.execute(cmd, env: { 'FOO' => 'BAR' })
          expect(execution_result.stdout.strip).to eq('BAR')
        end

        it 'can accept a hash of shell opts and extra args' do
          if subject.os_family == :windows
            cmd = 'Write-Host $env:FOO'
          else
            cmd = 'echo $FOO'
          end

          execution_result = subject.execute(cmd, { env: { 'FOO' => 'BAR' } }, 'baz')
          expect(execution_result.stdout.strip).to eq('BAR baz')
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

      describe '#task' do
        it 'returns a Task' do
          expect(subject.task('foo')).to be_an_instance_of Psychic::Task
        end

        it 'has a fluent #execute method' do
          execution_result = subject.task('foo').execute
          expect(execution_result.stdout).to include('hi')
        end
      end
    end

    context 'finding scripts' do
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
            scripts: {
              'foo' => '/path/to/foo.c',
              'bar' => '/path/to/bar.rb'
            }
          }
        end
        subject { described_class.new(cwd: Dir.pwd, hints: hints) }

        it 'returns the scripts from the hints' do
          scripts = subject.known_scripts
          expect(scripts.size).to eq(2)
          expect(scripts[0].name).to eq('foo')
          expect(scripts[0].source_file.to_s).to eq('/path/to/foo.c')
          expect(scripts[1].name).to eq('bar')
          expect(scripts[1].source_file.to_s).to eq('/path/to/bar.rb')
        end
      end

      describe '#script' do
        before(:each) do
          write_file 'samples/hi.rb', 'puts "hi"'
        end

        shared_examples 'executes' do
          it 'has a fluent #execute method' do
            execution_result = subject.script(script).execute
            expect(execution_result.stdout).to include('hi')
          end

          it 'returns a Script' do
            expect(subject.script('hi')).to be_an_instance_of Psychic::Script
          end

          it 'assigns source' do
            script = subject.script('hi')
            expect(script.source_file).to eq(Pathname('samples/hi.rb'))
            expect(script.source).to eq('puts "hi"')
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
