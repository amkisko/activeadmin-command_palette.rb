# frozen_string_literal: true

require_relative "lib/activeadmin/command_palette/version"

Gem::Specification.new do |spec|
  spec.name = "activeadmin-command-palette"
  spec.version = ActiveAdmin::CommandPalette::VERSION
  spec.authors = ["Andrei Makarov"]
  spec.email = ["contact@kiskolabs.com"]

  spec.summary = "Cmd+K command palette for ActiveAdmin 4"
  spec.description = "Keyboard command palette for ActiveAdmin 4: menu navigation, registered actions, and host-defined record finders."
  spec.license = "MIT"
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 3.4"

  repository_url = "https://github.com/amkisko/activeadmin-command_palette.rb"

  spec.homepage = repository_url
  spec.metadata = {
    "homepage_uri" => repository_url,
    "source_code_uri" => "#{repository_url}/tree/main",
    "changelog_uri" => "#{repository_url}/blob/main/CHANGELOG.md",
    "bug_tracker_uri" => "#{repository_url}/issues",
    "documentation_uri" => "#{repository_url}#readme",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(__dir__) do
    %w[
      CHANGELOG.md
      CODE_OF_CONDUCT.md
      CONTRIBUTING.md
      GOVERNANCE.md
      LICENSE.md
      README.md
      SECURITY.md
      activeadmin-command-palette.gemspec
    ].select { |path| File.file?(path) } +
      Dir["{app,config,lib,sig}/**/*"]
  end

  spec.require_paths = ["lib"]

  spec.add_dependency "activeadmin", ">= 4.0.0.beta23", "< 5"
  spec.add_dependency "importmap-rails"
  spec.add_dependency "rails", ">= 7.2"

  spec.add_development_dependency "appraisal", "~> 2"
  spec.add_development_dependency "bundler", ">= 2"
  spec.add_development_dependency "bundler-audit", "~> 0.9"
  spec.add_development_dependency "factory_bot", "~> 6"
  spec.add_development_dependency "polyrun", ">= 2.2.0"
  spec.add_development_dependency "prosopite", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13"
  spec.add_development_dependency "rbs", "~> 4"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "rspec-rails", ">= 6"
  spec.add_development_dependency "rubocop-rails", "~> 2.34"
  spec.add_development_dependency "rubocop-rspec", "~> 3.8"
  spec.add_development_dependency "rubocop-thread_safety", "~> 0.7"
  spec.add_development_dependency "sqlite3", ">= 2.9.6"
  spec.add_development_dependency "standard", "~> 1.52"
  spec.add_development_dependency "standard-custom", "~> 1.0"
  spec.add_development_dependency "standard-performance", "~> 1.8"
  spec.add_development_dependency "standard-rails", "~> 1.5"
  spec.add_development_dependency "standard-rspec", "~> 0.3"
end
