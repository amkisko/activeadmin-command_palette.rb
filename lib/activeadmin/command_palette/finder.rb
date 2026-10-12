# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class Finder
      class << self
        def options(kind:, query:, helpers:, user:)
          config = ActiveAdmin::CommandPalette.configuration
          term = query.to_s.strip
          return [] if term.length < config.min_query_length

          options_for_kind(
            kind: kind,
            query: term,
            helpers: helpers,
            user: user,
            limit: config.limit
          )
        end

        def options_for(kinds:, query:, helpers:, user:)
          config = ActiveAdmin::CommandPalette.configuration
          term = query.to_s.strip
          return [] if term.length < config.min_query_length

          collect_options(kinds: kinds, query: term, helpers: helpers, user: user, config: config)
        end

        def kinds
          ActiveAdmin::CommandPalette.configuration.finder_kinds
        end

        private

        def collect_options(kinds:, query:, helpers:, user:, config:)
          remaining = [config.limit.to_i, 0].max
          requested_kinds = bounded_kinds(kinds, config.search_kind_limit)

          requested_kinds.each_with_object([]) do |kind, results|
            break results if remaining.zero?

            items = options_for_kind(
              kind: kind,
              query: query,
              helpers: helpers,
              user: user,
              limit: remaining
            )
            results.concat(items)
            remaining -= items.length
          end
        end

        def bounded_kinds(kinds, limit)
          Array(kinds).first([limit.to_i, 0].max).map(&:to_s).uniq
        end

        def options_for_kind(kind:, query:, helpers:, user:, limit:)
          kind = kind.to_s
          finder = ActiveAdmin::CommandPalette.configuration.finders[kind]
          return [] unless finder

          results = finder.call(query: query, helpers: helpers, user: user, limit: limit)
          normalize_results(results, kind: kind, limit: limit)
        end

        def normalize_results(results, kind:, limit:)
          results.take(limit).map { |item| normalize(item, kind) }
        end

        def normalize(item, default_kind)
          hash = item.respond_to?(:to_h) ? item.to_h : item
          hash = hash.transform_keys(&:to_sym)
          normalized = normalized_fields(hash, default_kind)
          add_optional_fields(normalized, hash)
        end

        def normalized_fields(hash, default_kind)
          {
            id: hash[:id],
            kind: (hash[:kind] || default_kind).to_s,
            label: hash[:label].to_s,
            url: hash[:url].to_s,
            method: (hash[:method] || "get").to_s
          }
        end

        def add_optional_fields(normalized, hash)
          detail = hash[:detail].presence || hash[:subtitle].presence
          keywords = normalized_keywords(hash[:keywords])

          normalized[:detail] = detail.to_s if detail.present?
          normalized[:keywords] = keywords if keywords.any?
          normalized
        end

        def normalized_keywords(value)
          Array(value).map { |keyword| keyword.to_s.presence }.compact
        end
      end
    end
  end
end
