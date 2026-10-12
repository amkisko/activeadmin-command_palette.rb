# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    # Path helpers for finder callbacks. Uses the host application routes so
    # engine mounting cannot hide ActiveAdmin member paths.
    class UrlHelpers
      def method_missing(method_name, ...)
        helpers = Rails.application.routes.url_helpers
        if helpers.respond_to?(method_name)
          helpers.public_send(method_name, ...)
        else
          super
        end
      end

      def respond_to_missing?(method_name, include_private = false)
        Rails.application.routes.url_helpers.respond_to?(method_name) || super
      end
    end
  end
end
