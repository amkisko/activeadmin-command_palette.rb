# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class Engine < ::Rails::Engine
      engine_name "activeadmin_command_palette"

      initializer "activeadmin_command_palette.load_lib" do
        require "activeadmin/command_palette"
        ActiveAdmin::CommandPalette::Integration.install!
      end

      # Compile after ActiveAdmin loads admin files. A plain to_prepare can run after
      # ActiveAdmin.unload! and before load!, which would leave an empty catalog.
      initializer "activeadmin_command_palette.reload", after: :load_config_initializers do
        ActiveAdmin.after_load do
          ActiveAdmin::CommandPalette.reload!
        end

        if ActiveAdmin.application.loaded?
          ActiveAdmin::CommandPalette.reload!
        end
      end

      initializer "activeadmin_command_palette.assets" do |app|
        assets_path = root.join("app/assets")
        if app.config.respond_to?(:importmap)
          app.config.importmap.cache_sweepers << assets_path.join("controllers")
        end
      end

      initializer "activeadmin_command_palette.importmap", after: "active_admin.importmap" do
        next unless defined?(ActiveAdmin) && ActiveAdmin.respond_to?(:importmap) && ActiveAdmin.importmap

        ActiveAdmin.importmap.draw do
          pin "controllers/activeadmin_command_palette/command_palette_controller",
            to: "activeadmin_command_palette/command_palette_controller.js"
        end
      end

      initializer "activeadmin_command_palette.i18n" do
        I18n.load_path += Dir[root.join("config/locales/*.yml")]
      end

      initializer "activeadmin_command_palette.filter_parameters" do |app|
        app.config.filter_parameters |= [:q]
      end

      initializer "activeadmin_command_palette.helpers", after: :load_config_initializers do
        ActiveSupport.on_load(:action_controller) do
          helper ActiveAdmin::CommandPalette::Helper if respond_to?(:helper)
        end

        if defined?(ActiveAdmin::BaseController)
          ActiveAdmin::BaseController.helper ActiveAdmin::CommandPalette::Helper
        end
      end

      initializer "activeadmin_command_palette.view_paths", after: :add_view_paths do
        views_path = root.join("app/views").to_s
        ActiveSupport.on_load(:action_controller) do
          prepend_view_path(views_path)
        end
      end
    end
  end
end
