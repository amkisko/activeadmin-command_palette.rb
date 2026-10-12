# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ActiveAdmin::CommandPalette Tailwind entry" do
  def shell_class_tokens
    paths = [
      ActiveAdmin::CommandPalette::Engine.root.join(
        "app/views/active_admin/command_palette/_palette.html.erb"
      ),
      ActiveAdmin::CommandPalette::Engine.root.join(
        "app/assets/controllers/activeadmin_command_palette/command_palette_controller.js"
      )
    ]

    tokens = []
    paths.each do |path|
      text = File.read(path)
      text.scan(/class(?:Name)?\s*=\s*"([^"]+)"/).each { |match| tokens.concat(match[0].split) }
      text.scan(/=\s*"([^"]+)"/).each do |match|
        next unless match[0].match?(/\b(?:flex|px-|text-|bg-|dark:|hover:)/)

        tokens.concat(match[0].split)
      end
      text.scan(/`([^`]+)`/).each do |match|
        next unless match[0].match?(/\b(?:flex|px-|text-|bg-|dark:|hover:)/)

        tokens.concat(match[0].gsub(/\$\{[^}]+\}/, " ").split)
      end
    end
    tokens.reject(&:empty?).uniq.sort
  end

  it "exposes a Tailwind entry that lists every shell utility class", :aggregate_failures do
    entry_path = ActiveAdmin::CommandPalette.tailwind_entry_path
    expect(entry_path).to be_file

    entry = File.read(entry_path)
    shell_class_tokens.each do |token|
      expect(entry).to include(token), "missing #{token} in Tailwind entry"
    end
  end
end
