# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class OptionsController < ::ApplicationController
      before_action :prevent_command_palette_caching
      before_action :authenticate_command_palette_user!

      def index
        unless authorized_for_palette?
          head :forbidden
          return
        end

        render json: finder_options
      end

      private

      def finder_options
        arguments = {
          query: params[:q],
          helpers: UrlHelpers.new,
          user: current_palette_user
        }
        return Finder.options_for(kinds: params[:kinds], **arguments) if params[:kinds].present?

        Finder.options(kind: params[:kind], **arguments)
      end

      def prevent_command_palette_caching
        response.headers["Cache-Control"] = "no-store"
      end

      def authenticate_command_palette_user!
        method_name = ActiveAdmin.application.authentication_method
        if method_name.present?
          send(method_name)
        elsif current_palette_user.blank?
          head :unauthorized
        end
      end

      def authorized_for_palette?
        authorizer = ActiveAdmin::CommandPalette.configuration.authorize_with
        if authorizer
          authorizer.call(self)
        else
          current_palette_user.present?
        end
      end

      def current_palette_user
        method_name = ActiveAdmin.application.current_user_method
        return unless method_name.present?

        send(method_name)
      end
    end
  end
end
