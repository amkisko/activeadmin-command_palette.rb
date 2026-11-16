# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Command palette engine escape hatch", type: :request do
  around do |example|
    configuration = ActiveAdmin::CommandPalette.configuration
    previous_auto = configuration.auto_register_page
    previous_authorizer = configuration.authorize_with
    configuration.auto_register_page = false
    # Without the ActiveAdmin page registration, escape-hatch hosts must set
    # authorize_with (or fail closed). Mirror a signed-in admin gate here.
    configuration.authorize_with = ->(controller) { controller.current_user.present? }

    # Load ActiveAdmin resources before reload_routes so ActiveAdmin.routes
    # draws member helpers (for example admin_user_path) that finders need.
    ActiveAdmin.application.unload!
    ActiveAdmin.application.load!
    ActiveAdmin::CommandPalette.reload!
    Rails.application.reload_routes!
    draw_escape_hatch_routes!

    example.run
  ensure
    configuration.auto_register_page = previous_auto
    configuration.authorize_with = previous_authorizer
    ActiveAdmin.application.unload!
    ActiveAdmin.application.load!
    ActiveAdmin::CommandPalette.reload!
    Rails.application.reload_routes!
  end

  def draw_escape_hatch_routes!
    Rails.application.routes.disable_clear_and_finalize = true
    Rails.application.routes.draw do
      ActiveAdmin::CommandPalette::Routes.draw(self)
    end
  ensure
    Rails.application.routes.disable_clear_and_finalize = false
  end

  it "serves options through the mounted engine with ActiveAdmin auth", :aggregate_failures do
    user = create(:user, name: "Escape Admin", email: "escape-admin@example.com")
    person = create(:user, name: "Escape Person", email: "escape@example.com")
    sign_in(user)

    get active_admin_command_palette.options_path, params: {kind: "user", q: "Escape"}

    expect(response).to have_http_status(:ok)
    expect(response.parsed_body.map { |row| row["id"] }).to include(person.id)
  end

  it "rejects unauthenticated engine requests" do
    sign_out

    get active_admin_command_palette.options_path, params: {kind: "user", q: "Escape"}

    expect(response).to have_http_status(:unauthorized)
  end

  it "rejects signed-in engine requests when authorize_with and page config are absent" do
    configuration = ActiveAdmin::CommandPalette.configuration
    configuration.authorize_with = nil
    user = create(:user, name: "Closed Admin", email: "closed-admin@example.com")
    sign_in(user)

    get active_admin_command_palette.options_path, params: {kind: "user", q: "Escape"}

    expect(response).to have_http_status(:forbidden)
  end
end
