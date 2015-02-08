require 'simplecov'
SimpleCov.start

require 'rspec'
require 'crosstest/psychic'
require 'aruba'
require 'aruba/api'

# Includes shared examples
require 'crosstest/psychic/execution/default_strategy_spec'


# Config required for project
RSpec.configure do | config |
  config.include Aruba::Api
  config.before(:example) do
    @aruba_timeout_seconds = 30
    clean_current_dir
  end
end

# Configs recommended by RSpec
RSpec.configure do |config|
  # config.warnings = true # Unfortunately this produces too many warnings in third-party code
  config.disable_monkey_patching!
  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.expect_with :rspec do |expectations|
    # This option will default to `true` in RSpec 4.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Prevents you from mocking or stubbing a method that does not exist on
    # a real object. This is generally recommended, and will default to
    # `true` in RSpec 4.
    mocks.verify_partial_doubles = true
  end

  if config.files_to_run.one?
    # Use the documentation formatter for detailed output,
    # unless a formatter has already been configured
    # (e.g. via a command-line flag).
    config.default_formatter = 'doc'
  end

  config.profile_examples = 10
  config.order = :random
  Kernel.srand config.seed
end
