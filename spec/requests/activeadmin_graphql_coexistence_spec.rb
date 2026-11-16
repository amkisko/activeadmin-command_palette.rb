# frozen_string_literal: true

require "rails_helper"

RSpec.describe "admin GraphQL coexistence", type: :request do
  it "exposes the GraphQL endpoint next to ActiveAdmin-owned palette options" do
    user = create(:user, name: "Api Admin", email: "api-admin@example.com")
    sign_in(user)

    expect(admin_command_palette_options_path).to eq("/admin/command_palette/options")

    post "/admin/graphql",
      params: {query: "{ __typename }"}.to_json,
      headers: {"CONTENT_TYPE" => "application/json", "ACCEPT" => "application/json"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body["data"]).to be_present
  end
end
