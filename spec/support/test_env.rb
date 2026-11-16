# frozen_string_literal: true

require "open3"

# Slim browser helpers for gem system specs.
module TestEnv
  DOT_PLAYWRIGHT_VERSION = Pathname.new(__dir__).join("../../.playwright-version")
  ARTIFACTS_DIR = Pathname.new(__dir__).join("../../tmp/capybara")
  DEFAULT_CAPYBARA_PORT = 9887

  PLAYWRIGHT_VERSION = begin
    ev = ENV["PLAYWRIGHT_VERSION"].to_s.strip
    if !ev.empty?
      ev
    elsif DOT_PLAYWRIGHT_VERSION.exist?
      DOT_PLAYWRIGHT_VERSION.read.strip
    else
      "1.64.0"
    end
  end

  PLAYWRIGHT_COMMAND = ENV.fetch("PLAYWRIGHT_CLI") do
    "npx -y playwright@#{PLAYWRIGHT_VERSION}"
  end

  module_function

  def env_flag?(key)
    value = ENV[key]
    return false if value.nil?

    !%w[0 false no off].include?(value.to_s.strip.downcase) && !value.to_s.strip.empty?
  end

  def parallel_polyrun_worker?
    ENV.fetch("POLYRUN_SHARD_TOTAL", "0").to_i > 1
  end

  def parallel_port_offset
    return 0 unless parallel_polyrun_worker?

    idx = Integer(ENV.fetch("POLYRUN_SHARD_INDEX", "0"), exception: false)
    idx = 0 if idx.nil?
    idx * 10
  end

  def default_host
    ENV.fetch("CAPYBARA_SERVER_HOST", "localhost")
  end

  def default_port
    ENV.fetch("CAPYBARA_SERVER_PORT", (DEFAULT_CAPYBARA_PORT + parallel_port_offset).to_s).to_i
  end

  def artifacts_path
    Pathname(ENV.fetch("CAPYBARA_ARTIFACTS", ARTIFACTS_DIR.to_s))
  end

  def headed_browser?
    env_flag?("HEADFUL") || env_flag?("SCREENSHOTS") || env_flag?("VIDEO") || env_flag?("INSPECT")
  end

  def default_max_wait_time
    if headed_browser?
      30
    else
      ENV.fetch("CAPYBARA_MAX_WAIT", ENV["CI"].present? ? "30" : "15").to_i
    end
  end

  def window_size
    [
      ENV.fetch("CAPYBARA_WINDOW_WIDTH", "1280").to_i,
      ENV.fetch("CAPYBARA_WINDOW_HEIGHT", "900").to_i
    ]
  end

  # Single-string Open3 form matches playwright-ruby-client Transport (shells the CLI).
  def playwright_cli_available?
    out_status = Open3.capture2e("#{PLAYWRIGHT_COMMAND} --version")
    out_status.last.success?
  rescue Errno::ENOENT
    false
  end

  def playwright_hint
    "Install Playwright CLI and Chromium: PLAYWRIGHT_CLI='npx -y playwright@#{PLAYWRIGHT_VERSION}' " \
      "#{PLAYWRIGHT_COMMAND} install chromium"
  end

  def release_unusable_browsers_path!
    configured = ENV["PLAYWRIGHT_BROWSERS_PATH"].to_s.strip
    return if configured.empty?
    return if Dir.exist?(configured) && !Dir.glob(File.join(configured, "chromium*")).empty?

    ENV.delete("PLAYWRIGHT_BROWSERS_PATH")
  end

  def before_suite
    release_unusable_browsers_path!
    FileUtils.mkdir_p(artifacts_path)
  end

  def after_suite
  end
end
