# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::CommandPalette::Compiler do
  before do
    Rails.application.reload_routes!
    ActiveAdmin::CommandPalette.reload!
  end

  it "compiles user resource palette actions and finder registration", :aggregate_failures do
    compiled = described_class.compile
    ids = compiled[:actions].map { |entry| entry[:id] }
    kinds = compiled[:finders].map(&:kind)

    expect(ids).to include("view-user", "create-user", "edit-user", "delete-user", "open-chat-user")
    expect(kinds).to include("user", "article")
  end
end
