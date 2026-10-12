# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::CommandPalette::Finder do
  around do |example|
    previous = ActiveAdmin::CommandPalette.configuration
    ActiveAdmin::CommandPalette.reset_configuration!
    example.run
  ensure
    ActiveAdmin::CommandPalette.instance_variable_set(:@configuration, previous)
  end

  it "returns an empty list when the query is shorter than the minimum" do
    ActiveAdmin::CommandPalette.configure do |config|
      config.register_finder "workspace" do |**|
        [{id: 1, label: "Alpha", url: "/admin/workspaces/1"}]
      end
    end

    result = described_class.options(
      kind: "workspace",
      query: "a",
      helpers: nil,
      user: nil
    )

    expect(result).to eq([])
  end

  it "calls the registered finder and caps rows at the limit", :aggregate_failures do
    ActiveAdmin::CommandPalette.configure do |config|
      config.limit = 2
      config.register_finder "workspace" do |query:, limit:, **|
        expect(query).to eq("alpha")
        expect(limit).to eq(2)
        [
          {id: 1, label: "Alpha One", url: "/admin/workspaces/1"},
          {id: 2, label: "Alpha Two", url: "/admin/workspaces/2"},
          {id: 3, label: "Alpha Three", url: "/admin/workspaces/3"}
        ]
      end
    end

    result = described_class.options(
      kind: "workspace",
      query: "alpha",
      helpers: nil,
      user: :tester
    )

    expect(result.size).to eq(2)
    expect(result.first).to include(
      id: 1,
      kind: "workspace",
      label: "Alpha One",
      url: "/admin/workspaces/1",
      method: "get"
    )
  end

  it "stops consuming enumerable results at the configured limit" do
    yielded = 0
    results = Enumerator.new do |enumerator|
      3.times do |index|
        yielded += 1
        enumerator << {id: index, label: "Workspace #{index}", url: "/admin/workspaces/#{index}"}
      end
    end

    ActiveAdmin::CommandPalette.configure do |config|
      config.limit = 2
      config.register_finder("workspace") { |**| results }
    end

    result = described_class.options(
      kind: "workspace",
      query: "workspace",
      helpers: nil,
      user: nil
    )

    expect(result.size).to eq(2)
    expect(yielded).to eq(2)
  end

  it "keeps optional detail and keywords from the host finder", :aggregate_failures do
    ActiveAdmin::CommandPalette.configure do |config|
      config.register_finder "user" do |**|
        [{
          id: 9,
          label: "Ada",
          detail: "ada@example.com",
          keywords: %w[operator admin],
          url: "/admin/users/9"
        }]
      end
    end

    result = described_class.options(
      kind: "user",
      query: "ada",
      helpers: nil,
      user: nil
    )

    expect(result).to contain_exactly(
      hash_including(
        id: 9,
        kind: "user",
        label: "Ada",
        detail: "ada@example.com",
        keywords: %w[operator admin],
        url: "/admin/users/9",
        method: "get"
      )
    )
  end

  it "accepts subtitle as detail and omits blank optional fields", :aggregate_failures do
    ActiveAdmin::CommandPalette.configure do |config|
      config.register_finder "user" do |**|
        [{id: 1, label: "Bea", subtitle: "bea@example.com", keywords: [], url: "/admin/users/1"}]
      end
    end

    result = described_class.options(
      kind: "user",
      query: "bea",
      helpers: nil,
      user: nil
    ).first

    expect(result).to include(detail: "bea@example.com", label: "Bea")
    expect(result).not_to have_key(:keywords)
  end

  describe ".options_for" do
    it "caps finder work and results across requested kinds", :aggregate_failures do
      calls = []
      ActiveAdmin::CommandPalette.configure do |config|
        config.limit = 2
        config.search_kind_limit = 2
        %w[user article project].each do |kind|
          config.register_finder(kind) do |**|
            calls << kind
            [{id: kind, label: kind.capitalize, url: "/admin/#{kind}/1"}]
          end
        end
      end

      result = described_class.options_for(
        kinds: %w[user article project],
        query: "alpha",
        helpers: nil,
        user: :tester
      )

      expect(calls).to eq(%w[user article])
      expect(result.map { |item| item[:kind] }).to eq(%w[user article])
    end

    it "does not call another finder after filling the result budget" do
      ActiveAdmin::CommandPalette.configure do |config|
        config.limit = 1
        config.register_finder("user") do |**|
          [{id: 1, label: "Ada", url: "/admin/users/1"}]
        end
        config.register_finder("article") { raise "must not run" }
      end

      result = described_class.options_for(
        kinds: %w[user article],
        query: "alpha",
        helpers: nil,
        user: :tester
      )

      expect(result.map { |item| item[:label] }).to eq(["Ada"])
    end
  end
end
