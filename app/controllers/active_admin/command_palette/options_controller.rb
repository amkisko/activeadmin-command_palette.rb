# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    # Escape-hatch JSON options when the engine is mounted and
    # `auto_register_page` is false (RFC 0009). Uses the same ActiveAdmin
    # authentication_method / authorization adapter contract as the page.
    class OptionsController < ::ApplicationController
      include OptionsAction

      protect_from_forgery with: :exception

      before_action :authenticate_command_palette_user!
      before_action :authorize_command_palette_access!

      def index
        render_command_palette_options
      end
    end
  end
end
