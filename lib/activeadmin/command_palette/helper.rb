# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    module Helper
      CONTROLLER_NAME = "activeadmin-command-palette--command-palette"

      def command_palette_controller_name
        CONTROLLER_NAME
      end

      def command_palette_navigate_items
        Catalog.navigate(self)
      end

      def command_palette_action_items
        Catalog.actions(self, context: command_palette_context)
      end

      def command_palette_options_url
        active_admin_command_palette.options_path
      end

      def command_palette_context
        config = active_admin_config_for_palette
        action = controller_action_for_palette
        namespace_name = config&.namespace&.name&.to_s.presence || "admin"

        return other_context(namespace_name, action) if config.blank?
        return page_context(namespace_name, action) if config.is_a?(ActiveAdmin::Page)

        resource_name = config.resource_class.name.demodulize
        resource_param = "id"
        record_param = params[resource_param].presence || params[:id].presence
        if record_param.blank? && %w[show edit update destroy].include?(action)
          record_param = resource_param_for_palette
        end

        {
          namespace: namespace_name,
          resource: resource_name,
          resource_param: resource_param,
          record_param: record_param,
          action: action,
          page: "resource"
        }
      end

      def command_palette_data_attributes
        prefix = CONTROLLER_NAME
        {
          "data-#{prefix}-navigate-value" => command_palette_navigate_items.to_json,
          "data-#{prefix}-actions-value" => command_palette_action_items.to_json,
          "data-#{prefix}-context-value" => command_palette_context.to_json,
          "data-#{prefix}-options-url-value" => command_palette_options_url,
          "data-#{prefix}-csrf-value" => form_authenticity_token,
          "data-#{prefix}-prefixes-value" => ActiveAdmin::CommandPalette.configuration.prefixes.to_json,
          "data-#{prefix}-kinds-value" => ActiveAdmin::CommandPalette.configuration.finder_kinds.to_json,
          "data-#{prefix}-min-query-length-value" => ActiveAdmin::CommandPalette.configuration.min_query_length,
          "data-#{prefix}-empty-value" => I18n.t("active_admin.command_palette.empty"),
          "data-#{prefix}-loading-value" => I18n.t("active_admin.command_palette.loading"),
          "data-#{prefix}-error-value" => I18n.t("active_admin.command_palette.error"),
          "data-#{prefix}-unauthorized-value" => I18n.t("active_admin.command_palette.unauthorized"),
          "data-#{prefix}-forbidden-value" => I18n.t("active_admin.command_palette.forbidden"),
          "data-#{prefix}-required-value" => I18n.t("active_admin.command_palette.required"),
          "data-#{prefix}-optional-value" => I18n.t("active_admin.command_palette.optional"),
          "data-#{prefix}-sign-in-path-value" => command_palette_sign_in_path,
          "data-#{prefix}-help-items-value" => command_palette_help_items.to_json
        }
      end

      def command_palette_sign_in_path
        if respond_to?(:new_user_session_path)
          new_user_session_path
        else
          "/user/sign_in"
        end
      end

      def command_palette_help_items
        [
          {id: "help-go", kind: "help", label: I18n.t("active_admin.command_palette.help.go"), url: nil},
          {id: "help-actions", kind: "help", label: I18n.t("active_admin.command_palette.help.actions"), url: nil},
          {id: "help-resource", kind: "help", label: I18n.t("active_admin.command_palette.help.resource"), url: nil},
          {id: "help-modes", kind: "help", label: I18n.t("active_admin.command_palette.help.modes"), url: nil}
        ]
      end

      def render_command_palette
        render partial: "active_admin/command_palette/palette"
      end

      private

      def active_admin_config_for_palette
        return active_admin_config if respond_to?(:active_admin_config)

        nil
      end

      def controller_action_for_palette
        return controller.action_name.to_s if respond_to?(:controller) && controller.respond_to?(:action_name)

        "other"
      end

      def resource_param_for_palette
        return resource.to_param if respond_to?(:resource) && resource.respond_to?(:to_param)

        nil
      end

      def other_context(namespace_name, action)
        {
          namespace: namespace_name,
          resource: nil,
          resource_param: nil,
          record_param: nil,
          action: action,
          page: "other"
        }
      end

      def page_context(namespace_name, action)
        {
          namespace: namespace_name,
          resource: nil,
          resource_param: nil,
          record_param: nil,
          action: action,
          page: "page"
        }
      end
    end
  end
end
