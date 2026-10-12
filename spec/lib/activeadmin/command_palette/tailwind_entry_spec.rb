# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::CommandPalette do
  UTILITY_HINT = /\b(?:flex|px-|text-|bg-|dark:|hover:)/

  def shell_source_paths
    root = described_class::Engine.root
    [
      root.join("app/views/active_admin/command_palette/_palette.html.erb"),
      root.join("app/assets/controllers/activeadmin_command_palette/command_palette_controller.js")
    ]
  end

  def tokens_from_class_attributes(text)
    text.scan(/class(?:Name)?\s*=\s*"([^"]+)"/).flat_map { |match| match[0].split }
  end

  def tokens_from_quoted_utilities(text)
    text.scan(/=\s*"([^"]+)"/).flat_map do |match|
      next [] unless match[0].match?(UTILITY_HINT)

      match[0].split
    end
  end

  def tokens_from_template_literals(text)
    text.scan(/`([^`]+)`/).flat_map do |match|
      next [] unless match[0].match?(UTILITY_HINT)

      match[0].gsub(/\$\{[^}]+\}/, " ").split
    end
  end

  def shell_class_tokens
    shell_source_paths.flat_map do |path|
      text = File.read(path)
      tokens_from_class_attributes(text) +
        tokens_from_quoted_utilities(text) +
        tokens_from_template_literals(text)
    end.reject(&:empty?).uniq.sort
  end

  it "exposes a Tailwind entry that lists every shell utility class", :aggregate_failures do
    entry_path = described_class.tailwind_entry_path
    expect(entry_path).to be_file

    entry = File.read(entry_path)
    shell_class_tokens.each do |token|
      expect(entry).to include(token), "missing #{token} in Tailwind entry"
    end
  end
end
