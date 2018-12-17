# frozen_string_literal: true

require "bundler/setup"

ENV['GRAPHQL_RUBY_VERSION'] ||= '1_8'

if ENV['COVERALLS_REPO_TOKEN']
  require 'simplecov'
  SimpleCov.add_filter('spec')
  require 'coveralls'
  Coveralls.wear!
end

require 'batch-loader'
require "graphql/errors"

require 'fixtures/post'
require 'fixtures/schema'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end
