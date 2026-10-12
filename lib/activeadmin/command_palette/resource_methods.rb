# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    module ResourceMethods
      def command_palette_config
        @command_palette_config ||= ResourceConfig.new
      end
    end
  end
end
