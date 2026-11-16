# frozen_string_literal: true

# RFC 0009: options path owned by ActiveAdmin.routes when auto_register_page.
return unless ActiveAdmin::CommandPalette.configuration.auto_register_page

ActiveAdmin.register_page "Command Palette" do
  menu false

  controller do
    include ActiveAdmin::CommandPalette::OptionsAction

    # Keep CSRF on the page-owned options path even if the host ApplicationController
    # template omits protect_from_forgery (same contract as the engine escape hatch).
    protect_from_forgery with: :exception

    def authorize_access!
      authorize_command_palette_access!
    end

    def index
      redirect_to active_admin_root
    end
  end

  page_action :options, method: [:get, :post] do
    render_command_palette_options
  end
end
