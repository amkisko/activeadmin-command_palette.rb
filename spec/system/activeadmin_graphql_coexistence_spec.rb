# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Command palette with admin GraphQL", type: :system do
  before do
    create(:user, name: "Graph Admin", email: "graph-admin@rails.fi")
  end

  it "boots ActiveAdmin with GraphQL and keeps the palette interactive", :aggregate_failures do
    visit admin_root_path

    find("[data-test-command-palette-open]").click
    dialog = find('[data-activeadmin-command-palette--command-palette-target="dialog"]:not(.hidden)')
    expect(dialog).to be_present

    payload = page.driver.with_playwright_page do |browser_page|
      browser_page.evaluate(<<~'JS')
        async () => {
          const response = await fetch("/admin/graphql", {
            method: "POST",
            headers: {
              "Content-Type": "application/json",
              "Accept": "application/json",
              "X-CSRF-Token": document.querySelector("meta[name='csrf-token']")?.content || ""
            },
            credentials: "same-origin",
            body: JSON.stringify({ query: "{ __typename }" })
          })
          return { status: response.status, body: await response.json() }
        }
      JS
    end

    expect(payload.fetch("status")).to eq(200)
    expect(payload.dig("body", "data")).to be_present

    dialog.find('[role="combobox"]').send_keys("Dashboard")
    expect(dialog).to have_css('[role="option"]', text: /Dashboard/i)
  end
end
