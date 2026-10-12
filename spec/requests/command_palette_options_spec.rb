# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Command palette options", type: :request do
  describe "GET /admin/command_palette/options" do
    it "rejects unauthenticated requests" do
      sign_out

      get active_admin_command_palette.options_path, params: {kind: "user", q: "alpha"}

      expect(response).to have_http_status(:unauthorized)
    end

    context "when signed in" do
      let(:user) { create(:user, name: "Palette Admin", email: "palette-admin@example.com") }

      before { sign_in(user) }

      it "returns forbidden when the signed-in user is not authorized" do
        configuration = ActiveAdmin::CommandPalette.configuration
        previous_authorizer = configuration.authorize_with
        configuration.authorize_with = ->(_controller) { false }

        get active_admin_command_palette.options_path, params: {kind: "user", q: "alpha"}

        expect(response).to have_http_status(:forbidden)
      ensure
        configuration.authorize_with = previous_authorizer
      end

      it "returns an empty list for queries shorter than two characters" do
        create(:user, name: "Alpha Person", email: "alpha@example.com")

        get active_admin_command_palette.options_path, params: {kind: "user", q: "a"}

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to eq([])
      end

      it "finds a user by name", :aggregate_failures do
        person = create(:user, name: "Alpha Person", email: "alpha@example.com")

        get active_admin_command_palette.options_path, params: {kind: "user", q: "Alpha"}

        expect(response).to have_http_status(:ok)
        body = response.parsed_body
        expect(body.map { |row| row["id"] }).to include(person.id)
        expect(body.find { |row| row["id"] == person.id }).to include(
          "kind" => "user",
          "label" => "Alpha Person",
          "url" => admin_user_path(person)
        )
      end

      it "finds an article by title" do
        article = create(:article, title: "Palette Notes")

        get active_admin_command_palette.options_path, params: {kind: "article", q: "Palette"}

        expect(response).to have_http_status(:ok)
        expect(response.parsed_body).to contain_exactly(hash_including(
          "id" => article.id,
          "kind" => "article",
          "label" => "Palette Notes",
          "url" => admin_article_path(article)
        ))
      end
    end
  end

  describe "POST /admin/command_palette/options" do
    let(:user) { create(:user, name: "Palette Admin", email: "palette-admin@example.com") }

    before { sign_in(user) }

    it "searches several kinds with one private response", :aggregate_failures do
      person = create(:user, name: "Shared Term", email: "shared@example.com")
      article = create(:article, title: "Shared Term")

      post active_admin_command_palette.options_path,
        params: {kinds: %w[user article], q: "Shared"},
        as: :json

      expect(response).to have_http_status(:ok)
      expect(response.headers["Cache-Control"]).to include("no-store")
      expect(response.parsed_body).to include(
        hash_including("id" => person.id, "kind" => "user"),
        hash_including("id" => article.id, "kind" => "article")
      )
    end

    it "filters the query parameter from application logs" do
      parameter_filter = ActiveSupport::ParameterFilter.new(Rails.application.config.filter_parameters)
      filtered = parameter_filter.filter("q" => "private search")

      expect(filtered["q"]).to eq("[FILTERED]")
    end
  end
end
