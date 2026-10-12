# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    module DSL
      def command_palette(&block)
        definition = ResourceDSL.new(config.command_palette_config)
        definition.instance_exec(&block) if block
        config.command_palette_config
      end
    end
  end
end
