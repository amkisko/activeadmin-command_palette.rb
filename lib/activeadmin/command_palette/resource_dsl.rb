# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class ResourceDSL
      def initialize(config)
        @config = config
      end

      def kind(value)
        @config.enable!
        @config.kind = value.to_s
      end

      def noun(value)
        @config.enable!
        @config.noun = value.to_s
      end

      def label_method(value)
        @config.enable!
        @config.label_method = value.to_sym
      end

      def order(value)
        @config.enable!
        @config.order_column = value.to_sym
      end

      def find_by(*columns)
        @config.find_by(*columns)
      end

      def actions(*names)
        @config.actions(*names)
      end

      def create(help: nil, params: [])
        @config.create(help: help, params: params)
      end

      def member(label, **options)
        @config.member(label, **options)
      end
    end
  end
end
