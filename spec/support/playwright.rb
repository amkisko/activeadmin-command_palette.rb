# frozen_string_literal: true

# NOTE: https://playwright-ruby-client.vercel.app/docs/article/guides/rails_integration
require "capybara"
require "capybara-playwright-driver"
require "fileutils"
require "playwright"
require_relative "test_env"

TestEnv.release_unusable_browsers_path!

Capybara.raise_server_errors = true
# Name must not be :playwright — Rails SystemTesting replaces that registration
# with `npx playwright` (often a mismatched Chromium revision).
Capybara.default_driver = Capybara.javascript_driver = :railsfi
Capybara.default_max_wait_time = TestEnv.default_max_wait_time
Capybara.server_host = TestEnv.default_host
Capybara.server_port = TestEnv.default_port
Capybara.save_path = TestEnv.artifacts_path.to_s
FileUtils.mkdir_p(Capybara.save_path)

window_width, window_height = TestEnv.window_size
page_options = {
  viewport: {width: window_width, height: window_height},
  screen: {width: window_width, height: window_height}
}

Capybara.register_driver(:railsfi) do |app|
  Capybara::Playwright::Driver.new(
    app,
    timeout: Capybara.default_max_wait_time,
    default_navigation_timeout: Capybara.default_max_wait_time,
    browser_type: ENV.fetch("BROWSER", "chromium").to_sym,
    headless: !TestEnv.headed_browser?,
    playwright_cli_executable_path: TestEnv::PLAYWRIGHT_COMMAND,
    **page_options
  )
end

module PlaywrightHelpers
  def playwright_page
    page.driver.with_playwright_page { |handle| return handle }
  end
end

module SystemUrlOptions
  module_function

  def apply!
    host = Capybara.server_host
    port = Capybara.server_port
    @previous_controller = Rails.application.config.action_controller.default_url_options
    Rails.application.config.action_controller.default_url_options ||= {}
    @targets = [
      Rails.application.default_url_options,
      Rails.application.routes.default_url_options,
      Rails.application.config.action_controller.default_url_options
    ]
    @previous = @targets.map(&:dup)
    @targets.each do |options|
      options[:host] = host
      options[:port] = port if port
      options[:protocol] = "http"
    end
  end

  def restore!
    return if @previous.nil?

    @targets.zip(@previous).each do |options, saved|
      options.clear
      options.merge!(saved)
    end
    Rails.application.config.action_controller.default_url_options = @previous_controller
  ensure
    @previous = nil
    @targets = nil
    @previous_controller = nil
  end
end

RSpec.configure do |config|
  config.define_derived_metadata(type: :system) do |metadata|
    metadata[:slow] = true
  end

  config.include PlaywrightHelpers, type: :system

  config.before(:each, type: :system) do
    TestEnv.before_suite
    skip TestEnv.playwright_hint unless TestEnv.playwright_cli_available?
  end

  config.after(:suite) do
    TestEnv.after_suite
  end

  config.around(type: :system) do |example|
    SystemUrlOptions.apply!
    example.run
  ensure
    SystemUrlOptions.restore!
  end

  config.prepend_before(:each, type: :system) do
    driven_by Capybara.javascript_driver
  end

  config.after(:each, type: :system) do
    Capybara.reset_sessions!
  end
end
