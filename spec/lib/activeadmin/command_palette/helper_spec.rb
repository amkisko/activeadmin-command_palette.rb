# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::CommandPalette::Helper do
  before do
    Rails.application.reload_routes!
  end

  let(:helper_host) do
    Class.new do
      include ActiveAdmin::CommandPalette::Helper

      attr_accessor :active_admin_config, :params, :controller_action, :resource_record

      def initialize
        @params = {}
        @controller_action = "index"
      end

      def controller
        action = controller_action
        Object.new.tap do |instance|
          instance.define_singleton_method(:action_name) { action }
        end
      end

      def resource
        resource_record
      end

      def form_authenticity_token
        "token"
      end

      def active_admin_command_palette
        Object.new.tap do |routes|
          routes.define_singleton_method(:options_path) { "/admin/command_palette/options" }
        end
      end

      def command_palette_navigate_items
        []
      end

      def command_palette_action_items
        []
      end
    end.new
  end

  describe "#command_palette_context" do
    it "marks ActiveAdmin pages without a resource" do
      page_config = ActiveAdmin.application.namespaces[:admin].resources.find { |resource|
        resource.is_a?(ActiveAdmin::Page) && resource.name == "Dashboard"
      }
      helper_host.active_admin_config = page_config
      helper_host.controller_action = "index"

      expect(helper_host.command_palette_context).to include(
        resource: nil,
        record_param: nil,
        action: "index",
        page: "page"
      )
    end

    it "exposes resource and record on show", :aggregate_failures do
      resource_config = ActiveAdmin.application.namespaces[:admin].resources["User"]
      helper_host.active_admin_config = resource_config
      helper_host.controller_action = "show"
      helper_host.params = {id: "99"}

      expect(helper_host.command_palette_context).to include(
        resource: "User",
        resource_param: "id",
        record_param: "99",
        action: "show",
        page: "resource"
      )
    end

    it "falls back to resource#to_param when params lack id" do
      resource_config = ActiveAdmin.application.namespaces[:admin].resources["User"]
      record = Object.new
      record.define_singleton_method(:to_param) { "slug-1" }

      helper_host.active_admin_config = resource_config
      helper_host.controller_action = "show"
      helper_host.params = {}
      helper_host.resource_record = record

      expect(helper_host.command_palette_context[:record_param]).to eq("slug-1")
    end
  end

  describe "#command_palette_data_attributes" do
    it "includes a context value" do
      helper_host.controller_action = "index"
      attrs = helper_host.command_palette_data_attributes
      key = "data-activeadmin-command-palette--command-palette-context-value"

      expect(attrs[key]).to be_present
      expect(JSON.parse(attrs[key])).to include("action" => "index")
    end

    it "passes search and status behavior to the client", :aggregate_failures do
      configuration = ActiveAdmin::CommandPalette.configuration
      previous_minimum = configuration.min_query_length
      configuration.min_query_length = 1
      attrs = helper_host.command_palette_data_attributes
      prefix = "data-activeadmin-command-palette--command-palette"

      expect(attrs["#{prefix}-min-query-length-value"]).to eq(1)
      expect(attrs["#{prefix}-forbidden-value"]).to eq(I18n.t("active_admin.command_palette.forbidden"))
      expect(attrs["#{prefix}-required-value"]).to eq(I18n.t("active_admin.command_palette.required"))
      expect(attrs["#{prefix}-optional-value"]).to eq(I18n.t("active_admin.command_palette.optional"))
    ensure
      configuration.min_query_length = previous_minimum
    end
  end
end
