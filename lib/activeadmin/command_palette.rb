# frozen_string_literal: true

require "activeadmin/command_palette/version"
require "activeadmin/command_palette/configuration"
require "activeadmin/command_palette/resource_config"
require "activeadmin/command_palette/resource_dsl"
require "activeadmin/command_palette/resource_methods"
require "activeadmin/command_palette/dsl"
require "activeadmin/command_palette/compiler"
require "activeadmin/command_palette/catalog"
require "activeadmin/command_palette/finder"
require "activeadmin/command_palette/helper"
require "activeadmin/command_palette/url_helpers"
require "activeadmin/command_palette/integration"

module ActiveAdmin
  module CommandPalette
    class << self
      def configuration
        @configuration ||= Configuration.new
      end

      def configure
        yield configuration
      end

      def reset_configuration!
        @configuration = Configuration.new
      end

      def reload!
        configuration.reload!
      end
    end
  end
end

require "activeadmin/command_palette/engine"
