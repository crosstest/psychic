module Omnitest
  RSpec.describe Shell do
    subject { Psychic.new(cwd: current_dir).shell }

    let(:is_windows?) do
      RbConfig::CONFIG['host_os'] =~ /mswin|msys|mingw|cygwin|bccwin|wince|emc/
    end

    let(:pwd_cmd) { is_windows? ? 'echo %cd%' : 'pwd' }

    describe '#shell' do
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
        execution_result = subject.execute('echo hi', {})
        expect(execution_result).to be_an_instance_of Shell::ExecutionResult
        expect(execution_result.command).to eq('echo hi')
        expect(execution_result.stdout.strip).to eq('hi')
        expect(execution_result.exitstatus).to eq(0)
        expect(execution_result).to be_successful
        expect { execution_result.error! }.to_not raise_error
      end

      it 'raises an ExecutionError if the command was not found' do
        execution_error = begin
          subject.execute('missing', {})
          # Raised immediately by MixLib on Linux, but not by Buff or on Windows
          execution_result.error!
        rescue => e
          e
        end

        expect(execution_error).to be_an_instance_of Shell::ExecutionError
        execution_result = execution_error.execution_result
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
          execution_result_without_cwd = subject.execute(pwd_cmd, {})
          execution_result_with_cwd = subject.execute(pwd_cmd, cwd: current_aruba_dir)
          expect(Pathname(execution_result_without_cwd.stdout.strip)).to eq(Pathname(current_ruby_dir))
          expect(Pathname(execution_result_with_cwd.stdout.strip)).to eq(Pathname(current_aruba_dir))
        end
      end
    end
  end
end
