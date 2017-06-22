require 'rails_helper'

require 'rspec/rails'

RSpec.configure do |config|
  config.before(:suite) do
    DatabaseRewinder.clean_all
    require Rails.root.join("db", "seeds")
  end

  config.before(:each) do
    DatabaseRewinder.clean
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups
end
