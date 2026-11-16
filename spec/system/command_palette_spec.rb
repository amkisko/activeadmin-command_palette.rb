# frozen_string_literal: true

require "rails_helper"

RSpec.describe "ActiveAdmin command palette", type: :system do
  def palette_dialog(visible: true)
    find(
      '[data-activeadmin-command-palette--command-palette-target="dialog"]',
      visible: visible
    )
  end

  def palette_query
    palette_dialog.find('[role="combobox"]')
  end

  def dialog_closed?
    page.has_css?(
      '[data-activeadmin-command-palette--command-palette-target="dialog"].hidden',
      visible: :hidden
    )
  end

  before do
    create(:user, name: "Palette Admin", email: "palette-admin@rails.fi")
    visit admin_root_path
  end

  it "opens from the header control and closes with Escape", :aggregate_failures do
    expect(dialog_closed?).to be(true)

    find("[data-test-command-palette-open]").click

    expect(palette_dialog[:class]).not_to include("hidden")
    expect(palette_query["aria-expanded"]).to eq("true")
    expect(page.evaluate_script("document.activeElement.getAttribute('role')")).to eq("combobox")

    palette_query.send_keys(:escape)

    expect(dialog_closed?).to be(true)
  end

  it "opens with Ctrl+K and filters navigate items", :aggregate_failures do
    page.execute_script(
      "document.dispatchEvent(new KeyboardEvent('keydown', {key: 'k', ctrlKey: true, bubbles: true}))"
    )

    expect(palette_dialog[:class]).not_to include("hidden")
    palette_query.send_keys("Dashboard")

    expect(palette_dialog).to have_css('[role="option"]', text: /Dashboard/i)
  end

  it "searches records through the ActiveAdmin options endpoint", :aggregate_failures do
    person = create(:user, name: "Alpha Person", email: "alpha@rails.fi")

    find("[data-test-command-palette-open]").click
    palette_query.send_keys("Alpha")

    expect(palette_dialog).to have_css('[role="option"]', text: "Alpha Person", wait: 5)
    expect(palette_dialog).to have_css('[role="option"]', text: person.email)
  end
end
