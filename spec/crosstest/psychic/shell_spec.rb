module Crosstest
  RSpec.describe Shell do
    subject { described_class.shell }

    describe '.shell' do
      it 'returns an appropriate shell for the platform' do
        if RUBY_PLATFORM == 'java'
          expect(subject).to be_an_instance_of Shell::BuffShellOutExecutor
        else
          expect(subject).to be_an_instance_of Shell::MixlibShellOutExecutor
        end
      end
    end

    describe '#execute' do
      it 'returns a successful ExecutionResult if it executes successfully' do
        execution_result = subject.execute("echo 'hi'", {})
        expect(execution_result).to be_an_instance_of Shell::ExecutionResult
        expect(execution_result.command).to eq("echo 'hi'")
        expect(execution_result.stdout).to match(/\Ahi\Z/)
        expect(execution_result.exitstatus).to eq(0)
        expect(execution_result).to be_successful
        expect { execution_result.error! }.to_not raise_error
      end

      it 'returns an unsuccesful ExecutionResult if the command was not found' do
        execution_result = subject.execute('missing', {})
        expect(execution_result).to_not be_successful
        expect(execution_result.exitstatus).to_not eq(0)
        expect { execution_result.error! }.to raise_error(Shell::ExecutionError)
      end

      it 'returns an unsuccesful ExecutionResult if the command returns exits with a non-zero code' do
        execution_result = subject.execute("ruby -e 'exit 5'", {})
        expect(execution_result).to_not be_successful
        expect(execution_result.exitstatus).to eq(5)
        expect { execution_result.error! }.to raise_error(Shell::ExecutionError)
      end

      context 'with cwd' do
        it 'executes the command in the specified directory' do
          current_ruby_dir = Pathname(Dir.pwd).expand_path
          current_aruba_dir = Pathname(current_dir).expand_path
          expect(current_ruby_dir).to_not eq(current_aruba_dir)
          execution_result_without_cwd = subject.execute('pwd', {})
          execution_result_with_cwd = subject.execute('pwd', cwd: current_aruba_dir)
          expect(execution_result_without_cwd.stdout.strip).to eq(current_ruby_dir.to_s)
          expect(execution_result_with_cwd.stdout.strip).to eq(current_aruba_dir.to_s)
        end
      end
    end
  end
end
