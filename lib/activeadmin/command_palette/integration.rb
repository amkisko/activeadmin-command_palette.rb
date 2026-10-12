# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    module Integration
      class << self
        def install!
          return if @installed

          ActiveAdmin::Resource.include(ResourceMethods)
          ActiveAdmin::ResourceDSL.prepend(DSL)
          @installed = true
        end
      end
    end
  end
end
