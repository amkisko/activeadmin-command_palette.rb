# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class Configuration
      DEFAULT_MIN_QUERY_LENGTH = 2
      DEFAULT_LIMIT = 20
      DEFAULT_SEARCH_KIND_LIMIT = 20
      ALLOWED_METHODS = %w[get post put delete].freeze
      ALLOWED_SCOPES = %w[global collection member].freeze
      ALLOWED_WHENS = %w[any index show new edit].freeze

      attr_accessor :min_query_length, :limit, :search_kind_limit, :authorize_with, :default_finder
      attr_reader :finders, :actions, :prefixes

      def initialize
        @min_query_length = DEFAULT_MIN_QUERY_LENGTH
        @limit = DEFAULT_LIMIT
        @search_kind_limit = DEFAULT_SEARCH_KIND_LIMIT
        @finders = {}
        @manual_finders = {}
        @actions = []
        @global_actions = []
        @prefixes = {}
        @authorize_with = nil
        @default_finder = nil
      end

      def register_finder(kind, &block)
        raise ArgumentError, "finder block required" unless block

        kind = kind.to_s
        @manual_finders[kind] = block
        @finders[kind] = block
      end

      def register_prefix(prefix, kind:)
        @prefixes[prefix.to_s] = kind.to_s
      end

      # Global allow-list (non-resource shortcuts). Resource DSL actions merge in on reload!.
      def actions=(entries)
        @global_actions = Array(entries).map { |entry| normalize_action(entry) }
        @actions = @global_actions
      end

      def finder_kinds
        @finders.keys
      end

      def reload!
        compiled = Compiler.compile
        @finders = @manual_finders.dup
        compiled[:finders].each do |registration|
          next if @finders.key?(registration.kind)
          next if default_finder.blank?

          @finders[registration.kind] = finder_proc_for(registration)
        end
        @actions = @global_actions + compiled[:actions].map { |entry| normalize_action(entry) }
        self
      end

      private

      def finder_proc_for(registration)
        builder = default_finder
        lambda do |query:, helpers:, user:, limit:|
          builder.call(
            registration: registration,
            query: query,
            helpers: helpers,
            user: user,
            limit: limit
          )
        end
      end

      def normalize_action(entry)
        hash = entry.transform_keys(&:to_sym)
        raise ArgumentError, "action id required" if hash[:id].to_s.strip.empty?
        raise ArgumentError, "action label required" if hash[:label].to_s.strip.empty?

        method = (hash[:method] || "get").to_s.downcase
        unless ALLOWED_METHODS.include?(method)
          raise ArgumentError, "unsupported action method #{method.inspect}"
        end

        if %w[post put delete].include?(method) && hash[:confirm].to_s.strip.empty?
          raise ArgumentError, "POST, PUT, and DELETE actions require non-empty confirm text"
        end

        scope = (hash[:scope] || "global").to_s
        unless ALLOWED_SCOPES.include?(scope)
          raise ArgumentError, "unsupported action scope #{scope.inspect}"
        end

        when_list = normalize_when(hash[:when])
        params = Array(hash[:params]).map { |param| normalize_param(param) }
        query = normalize_query(hash[:query])

        normalized = hash.merge(
          method: method,
          scope: scope,
          when: when_list,
          params: params,
          query: query
        )
        normalized[:verb] = hash[:verb].to_s if hash[:verb].present?
        normalized[:resource] = hash[:resource].to_s if hash[:resource].present?
        normalized[:help] = hash[:help].to_s if hash[:help].present?
        normalized[:finder_kind] = hash[:finder_kind].to_s if hash[:finder_kind].present?
        normalized[:path_args] = Array(hash[:path_args]) if hash.key?(:path_args)
        normalized[:if] = hash[:if] if hash.key?(:if)
        normalized
      end

      def normalize_when(value)
        list = Array(value.nil? ? "any" : value).flat_map { |item| item.to_s.split(",") }.map(&:strip)
        list = ["any"] if list.empty?
        list.each do |item|
          unless ALLOWED_WHENS.include?(item)
            raise ArgumentError, "unsupported action when #{item.inspect}"
          end
        end
        list
      end

      def normalize_param(entry)
        hash = entry.transform_keys(&:to_sym)
        raise ArgumentError, "param name required" if hash[:name].to_s.strip.empty?

        {
          name: hash[:name].to_s,
          required: hash[:required] ? true : false,
          help: hash[:help]&.to_s,
          query_key: hash[:query_key]&.to_s
        }.compact
      end

      def normalize_query(value)
        return {} if value.blank?

        value.to_h.transform_keys(&:to_s).transform_values(&:to_s)
      end
    end
  end
end
