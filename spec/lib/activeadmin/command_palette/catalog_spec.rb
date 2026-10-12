# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::CommandPalette::Catalog do
  around do |example|
    previous = ActiveAdmin::CommandPalette.configuration
    ActiveAdmin::CommandPalette.reset_configuration!
    example.run
  ensure
    ActiveAdmin::CommandPalette.instance_variable_set(:@configuration, previous)
  end

  describe ".actions" do
    it "omits entries whose path helper is missing", :aggregate_failures do
      ActiveAdmin::CommandPalette.configure do |config|
        config.actions = [
          {id: "ok", label: "OK", url: "/admin/ok"},
          {id: "missing", label: "Missing", path: :missing_admin_path}
        ]
      end

      view = Object.new
      def view.missing_admin_path
        raise NoMethodError, "missing_admin_path"
      end

      def view.command_palette_context
        {namespace: "admin", resource: nil, resource_param: nil, record_param: nil, action: "index", page: "other"}
      end

      items = described_class.actions(view)

      expect(items.map { |item| item[:id] }).to eq(["ok"])
      expect(items.first[:url]).to eq("/admin/ok")
    end

    it "resolves path helpers when present" do
      ActiveAdmin::CommandPalette.configure do |config|
        config.actions = [
          {id: "jobs", label: "Jobs", path: :admin_jobs_path}
        ]
      end

      view = Object.new
      def view.admin_jobs_path
        "/admin/jobs"
      end

      def view.command_palette_context
        {namespace: "admin", resource: nil, resource_param: nil, record_param: nil, action: "index", page: "other"}
      end

      item = described_class.actions(view).first
      expect(item).to include(
        id: "jobs",
        kind: "action",
        label: "Jobs",
        url: "/admin/jobs",
        method: "get",
        scope: "global",
        when: ["any"]
      )
    end

    it "includes view actions without a url" do
      ActiveAdmin::CommandPalette.configure do |config|
        config.actions = [{
          id: "view-user",
          label: "View user",
          verb: "view",
          finder_kind: "user"
        }]
      end

      view = Object.new
      def view.command_palette_context
        {namespace: "admin", resource: nil, resource_param: nil, record_param: nil, action: "index", page: "other"}
      end

      expect(described_class.actions(view)).to contain_exactly(hash_including(
        id: "view-user",
        verb: "view",
        finder_kind: "user",
        url: nil
      ))
    end

    it "resolves member paths from context and omits them without a record", :aggregate_failures do
      ActiveAdmin::CommandPalette.configure do |config|
        config.actions = [{
          id: "edit-user",
          label: "Edit user",
          path: :edit_admin_user_path,
          scope: "member",
          when: "show",
          resource: "User",
          verb: "edit"
        }]
      end

      show_view = Object.new
      def show_view.edit_admin_user_path(id)
        "/admin/users/#{id}/edit"
      end

      def show_view.command_palette_context
        {
          namespace: "admin",
          resource: "User",
          resource_param: "id",
          record_param: "42",
          action: "show",
          page: "resource"
        }
      end

      index_view = Object.new
      def index_view.edit_admin_user_path(id)
        "/admin/users/#{id}/edit"
      end

      def index_view.command_palette_context
        {
          namespace: "admin",
          resource: "User",
          resource_param: "id",
          record_param: nil,
          action: "index",
          page: "resource"
        }
      end

      expect(described_class.actions(show_view)).to contain_exactly(hash_including(
        id: "edit-user",
        url: "/admin/users/42/edit",
        scope: "member"
      ))
      expect(described_class.actions(index_view)).to eq([])
    end

    it "keeps global create actions on unrelated resource pages" do
      ActiveAdmin::CommandPalette.configure do |config|
        config.actions = [{
          id: "create-user",
          label: "Create user",
          path: :new_admin_user_path,
          scope: "global",
          when: "any",
          resource: "User",
          verb: "create"
        }]
      end

      view = Object.new
      def view.new_admin_user_path
        "/admin/users/new"
      end

      def view.command_palette_context
        {
          namespace: "admin",
          resource: "Workspace",
          resource_param: "id",
          record_param: "7",
          action: "show",
          page: "resource"
        }
      end

      expect(described_class.actions(view).map { |item| item[:id] }).to eq(["create-user"])
    end

    it "interpolates query placeholders for member GET actions" do
      ActiveAdmin::CommandPalette.configure do |config|
        config.actions = [{
          id: "open-chat-user",
          label: "Open in chat",
          path: :admin_chat_path,
          path_args: [],
          scope: "member",
          when: "show",
          resource: "User",
          query: {context_selector: "user:%{record_param}"}
        }]
      end

      view = Object.new
      def view.admin_chat_path
        "/admin/chat"
      end

      def view.command_palette_context
        {
          namespace: "admin",
          resource: "User",
          resource_param: "id",
          record_param: "42",
          action: "show",
          page: "resource"
        }
      end

      expect(described_class.actions(view)).to contain_exactly(hash_including(
        id: "open-chat-user",
        url: "/admin/chat?context_selector=user%3A42"
      ))
    end

    it "omits actions whose if condition is false or fails in the view", :aggregate_failures do
      ActiveAdmin::CommandPalette.configure do |config|
        config.actions = [
          {id: "always", label: "Always", url: "/admin/always"},
          {id: "off", label: "Off", url: "/admin/off", if: false},
          {id: "flagged", label: "Flagged", url: "/admin/flagged", if: -> { feature_on? }}
        ]
      end

      on_view = Object.new
      def on_view.feature_on? = true

      def on_view.command_palette_context
        {namespace: "admin", resource: nil, resource_param: nil, record_param: nil, action: "index", page: "other"}
      end

      off_view = Object.new
      def off_view.feature_on? = false

      def off_view.command_palette_context
        {namespace: "admin", resource: nil, resource_param: nil, record_param: nil, action: "index", page: "other"}
      end

      expect(described_class.actions(on_view).map { |item| item[:id] }).to eq(%w[always flagged])
      expect(described_class.actions(off_view).map { |item| item[:id] }).to eq(%w[always])
    end
  end

  describe ".navigate" do
    it "walks leaf menu items with crumb labels" do
      leaf = Struct.new(:id, :label_text, :url_text, :child_items) do
        def label(_view) = label_text
        def url(_view) = url_text
        def items(_view) = child_items || []
      end

      child = leaf.new("users", "Users", "/admin/users", [])
      parent = leaf.new("team", "Team", nil, [child])
      menu = Object.new
      menu.define_singleton_method(:items) { |_view| [parent] }

      view = Object.new
      view.define_singleton_method(:current_menu) { menu }

      expect(described_class.navigate(view)).to eq([{
        id: "nav-users",
        kind: "navigate",
        label: "Team › Users",
        keywords: %w[team users],
        url: "/admin/users",
        method: "get"
      }])
    end

    it "returns an empty list when the menu is missing" do
      view = Object.new
      view.define_singleton_method(:current_menu) { nil }

      expect(described_class.navigate(view)).to eq([])
    end
  end
end
