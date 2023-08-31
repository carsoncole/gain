require 'simplecov'
SimpleCov.start 'rails' do
  add_filter 'lib'
  add_filter 'app/channels'
  add_filter 'app/mailers'
  add_filter 'app/jobs'
  add_filter 'vendor'
end


ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"
require "clearance/test_unit"

class ActiveSupport::TestCase
  include FactoryBot::Syntax::Methods
  # Run tests in parallel with specified workers
  # parallelize(workers: :number_of_processors)

  # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
  fixtures :all

  def system_test_signin(user)
    visit '/sign_in'
    fill_in "Email", with: user.email
    fill_in "Password", with: user.password
    within '#clearance' do
      click_on "Sign in"
    end
    sleep 0.25 # tests were occasionally failing without this
  end
end
