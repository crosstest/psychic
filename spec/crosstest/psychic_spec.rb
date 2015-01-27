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
    end

    context 'when scripts/* exist' do
      before(:each) do
        write_file 'scripts/bootstrap.sh', ''
        write_file 'scripts/foo.sh', ''
      end

      describe 'initialize' do
        it 'should create a ShellTaskFactory' do
          shell_task_factory = subject.task_factory_manager.active? Psychic::Factories::ShellTaskFactory
          expect(shell_task_factory).to_not be nil
          expect(shell_task_factory.cwd).to eq(current_dir)
        end
      end
    end
  end
end
