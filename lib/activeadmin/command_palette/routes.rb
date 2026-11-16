# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    # Explicit engine mount when `configuration.auto_register_page` is false
    # (RFC 0009). Auth stays on OptionsController; mapper placement does not
    # inherit ActiveAdmin config.
    module Routes
      def self.draw(mapper, at: "/admin/command_palette", as: "active_admin_command_palette")
        mapper.mount Engine => at, as: as
      end
    end
  end
end
