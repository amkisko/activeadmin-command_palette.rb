# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::CommandPalette::Configuration do
  subject(:config) { described_class.new }

  it "defaults combined search to twenty finder kinds" do
    expect(config.search_kind_limit).to eq(20)
  end

  describe "#actions=" do
    it "accepts GET actions without confirm and applies defaults", :aggregate_failures do
      config.actions = [{id: "jobs", label: "Jobs", url: "/admin/jobs"}]

      expect(config.actions.first).to include(
        id: "jobs",
        label: "Jobs",
        url: "/admin/jobs",
        method: "get",
        scope: "global",
        when: ["any"]
      )
    end

    it "accepts POST actions with confirm text" do
      config.actions = [{
        id: "wipe",
        label: "Wipe",
        url: "/admin/wipe",
        method: "post",
        confirm: "Wipe everything?"
      }]

      expect(config.actions.first).to include(method: "post", confirm: "Wipe everything?")
    end

    it "accepts DELETE actions with confirm text and contextual fields", :aggregate_failures do
      config.actions = [{
        id: "delete-user",
        label: "Delete user",
        path: :admin_user_path,
        method: "delete",
        confirm: "Delete this user?",
        scope: "member",
        when: "show",
        resource: "User",
        verb: "destroy"
      }]

      expect(config.actions.first).to include(
        method: "delete",
        confirm: "Delete this user?",
        scope: "member",
        when: ["show"],
        resource: "User",
        verb: "destroy"
      )
    end

    it "accepts view actions with finder_kind and help" do
      config.actions = [{
        id: "view-user",
        label: "View user",
        verb: "view",
        finder_kind: "user",
        help: "View user — type a name"
      }]

      expect(config.actions.first).to include(
        verb: "view",
        finder_kind: "user",
        help: "View user — type a name",
        method: "get"
      )
    end

    it "preserves if callables on actions" do
      gate = -> { false }
      config.actions = [{id: "gated", label: "Gated", url: "/admin/gated", if: gate}]

      expect(config.actions.first[:if]).to eq(gate)
    end

    it "normalizes create params" do
      config.actions = [{
        id: "create-user",
        label: "Create user",
        path: :new_admin_user_path,
        verb: "create",
        params: [{name: "email", required: false, help: "Email", query_key: "user[email]"}]
      }]

      expect(config.actions.first[:params]).to eq([{
        name: "email",
        required: false,
        help: "Email",
        query_key: "user[email]"
      }])
    end

    it "rejects POST actions without confirm text" do
      expect {
        config.actions = [{id: "wipe", label: "Wipe", url: "/admin/wipe", method: "post"}]
      }.to raise_error(ArgumentError, /confirm/)
    end

    it "rejects DELETE actions without confirm text" do
      expect {
        config.actions = [{id: "x", label: "X", url: "/x", method: "delete"}]
      }.to raise_error(ArgumentError, /confirm/)
    end

    it "accepts PUT actions with confirm text" do
      config.actions = [{
        id: "publish",
        label: "Publish",
        url: "/admin/publish",
        method: "put",
        confirm: "Publish?"
      }]

      expect(config.actions.first).to include(method: "put", confirm: "Publish?")
    end

    it "rejects unsupported methods" do
      expect {
        config.actions = [{id: "x", label: "X", url: "/x", method: "patch"}]
      }.to raise_error(ArgumentError, /unsupported action method/)
    end

    it "rejects unknown scopes" do
      expect {
        config.actions = [{id: "x", label: "X", url: "/x", scope: "nested"}]
      }.to raise_error(ArgumentError, /unsupported action scope/)
    end
  end
end
