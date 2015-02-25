Fabricator(:execution_result, from: Omnitest::Shell::ExecutionResult) do
  initialize_with do
    @_klass.new @_transient_attributes
  end # Hash based initialization
  transient command: 'sample command'
  transient exitstatus: 0
  transient stdout: ''
  transient stderr: ''
end
