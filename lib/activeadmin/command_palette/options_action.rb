# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    # Shared JSON options response for the ActiveAdmin page action and the
    # engine escape-hatch controller (RFC 0009).
    module OptionsAction
      extend ActiveSupport::Concern

      private

      def render_command_palette_options
        prevent_command_palette_caching
        render json: command_palette_finder_options
      end

      def command_palette_finder_options
        arguments = {
          query: params[:q],
          helpers: UrlHelpers.new,
          user: current_command_palette_user
        }
        return Finder.options_for(kinds: params[:kinds], **arguments) if params[:kinds].present?

        Finder.options(kind: params[:kind], **arguments)
      end

      def prevent_command_palette_caching
        response.headers["Cache-Control"] = "no-store"
      end

      def current_command_palette_user
        method_name = command_palette_active_admin_namespace&.current_user_method
        return unless method_name.present?

        send(method_name)
      end

      def command_palette_active_admin_namespace
        if respond_to?(:active_admin_namespace, true) && active_admin_namespace
          return active_admin_namespace
        end

        ActiveAdmin.application.namespaces[:admin] ||
          ActiveAdmin.application.namespaces.values.first
      end

      def command_palette_page_config
        if respond_to?(:active_admin_config, true) &&
            active_admin_config.is_a?(ActiveAdmin::Page) &&
            active_admin_config.name == "Command Palette"
          return active_admin_config
        end

        namespace = command_palette_active_admin_namespace
        return unless namespace

        namespace.resources.find do |resource|
          resource.is_a?(ActiveAdmin::Page) && resource.name == "Command Palette"
        end
      end

      def authenticate_command_palette_user!
        namespace = command_palette_active_admin_namespace
        method_name = namespace&.authentication_method
        if method_name.present?
          send(method_name)
        elsif current_command_palette_user.blank?
          head :unauthorized
        end
      end

      def authorize_command_palette_access!
        authorizer = ActiveAdmin::CommandPalette.configuration.authorize_with
        if authorizer
          head :forbidden unless authorizer.call(self)
          return
        end

        namespace = command_palette_active_admin_namespace
        page_config = command_palette_page_config
        if namespace.nil? || page_config.nil?
          head :forbidden
          return
        end

        adapter_class = command_palette_authorization_adapter(namespace)
        adapter = adapter_class.new(page_config, current_command_palette_user)
        head :forbidden unless adapter.authorized?(ActiveAdmin::Authorization::READ, page_config)
      end

      def command_palette_authorization_adapter(namespace)
        adapter = namespace.authorization_adapter
        adapter.is_a?(String) ? adapter.constantize : adapter
      end
    end
  end
end
