# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class ResourceConfig
      attr_accessor :kind, :noun, :label_method, :order_column
      attr_reader :find_columns, :standard_actions, :create_help, :create_params, :members

      def initialize
        @kind = nil
        @noun = nil
        @label_method = nil
        @order_column = nil
        @find_columns = []
        @standard_actions = []
        @create_help = nil
        @create_params = []
        @members = []
        @enabled = false
      end

      def enabled?
        @enabled
      end

      def enable!
        @enabled = true
      end

      def find_by(*columns)
        enable!
        @find_columns = columns.flatten.map(&:to_s)
      end

      def actions(*names)
        enable!
        @standard_actions = names.flatten.map(&:to_sym)
      end

      def create(help: nil, params: [])
        enable!
        @create_help = help
        @create_params = Array(params).map { |param| param.transform_keys(&:to_sym) }
      end

      def member(label, **options)
        enable!
        @members << options.transform_keys(&:to_sym).merge(label: label.to_s)
      end
    end
  end
end
