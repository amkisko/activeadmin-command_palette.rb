# frozen_string_literal: true

require "rails_helper"

RSpec.describe "active_admin/command_palette/_palette", type: :view do
  it "labels the search field and traps keyboard focus in the dialog", :aggregate_failures do
    render partial: "active_admin/command_palette/palette"
    fragment = Nokogiri::HTML.fragment(rendered)
    dialog = fragment.at_css('[role="dialog"]')
    query = fragment.at_css('input[role="combobox"]')
    status = fragment.at_css('[role="status"]')

    expect(query["aria-label"]).to eq(I18n.t("active_admin.command_palette.query_label"))
    expect(dialog["data-action"]).to include("#onDialogKeydown")
    expect(status["aria-live"]).to eq("polite")
  end
end
