# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class Catalog
      class << self
        def navigate(view)
          menu = view.try(:current_menu)
          return [] if menu.blank?

          walk_menu(menu, view)
        rescue NoMethodError, TypeError, ArgumentError
          []
        end

        def actions(view, context: nil)
          context = normalize_context(context || view.try(:command_palette_context))

          ActiveAdmin::CommandPalette.configuration.actions.filter_map do |entry|
            next unless matches_context?(entry, context)
            next unless enabled?(entry, view)

            verb = entry[:verb].to_s
            url = resolve_url(view, entry, context)
            next if url.blank? && verb != "view"

            item = {
              id: entry[:id],
              kind: "action",
              label: entry[:label],
              url: url,
              method: (entry[:method] || "get").to_s,
              confirm: entry[:confirm],
              scope: entry[:scope],
              when: entry[:when],
              resource: entry[:resource],
              verb: entry[:verb],
              params: entry[:params],
              help: entry[:help],
              finder_kind: entry[:finder_kind]
            }
            detail = entry[:detail].presence || entry[:subtitle].presence
            item[:detail] = detail.to_s if detail.present?
            keywords = Array(entry[:keywords]).map { |keyword| keyword.to_s.presence }.compact
            item[:keywords] = keywords if keywords.any?
            item
          end
        end

        def resolve_url(view, entry, context = {})
          context = normalize_context(context)
          url =
            if entry[:url].present?
              interpolate(entry[:url], context)
            else
              path = entry[:path]
              return if path.blank?

              args = path_args_for(entry, context)
              return if entry[:scope].to_s == "member" && !entry.key?(:path_args) && args.empty?

              view.public_send(path, *args)
            end

          append_query(url, entry[:query], context)
        rescue NoMethodError, ActionController::UrlGenerationError
          nil
        end

        def matches_context?(entry, context)
          context = normalize_context(context)
          scope = (entry[:scope] || "global").to_s
          when_list = Array(entry[:when] || "any").map(&:to_s)
          action = gated_action(context[:action])

          return false if scope == "member" && context[:record_param].blank?
          return false if scope == "collection" && action != "index"
          return false unless when_list.include?("any") || when_list.include?(action) || when_list.include?(context[:action].to_s)

          if %w[member collection].include?(scope) && entry[:resource].present?
            return false if context[:resource].to_s != entry[:resource].to_s
          end

          true
        end

        def enabled?(entry, view)
          return true unless entry.key?(:if)

          condition = entry[:if]
          return !!condition unless condition.respond_to?(:call)

          !!view.instance_exec(&condition)
        end

        private

        def normalize_context(context)
          hash = (context || {}).transform_keys(&:to_sym)
          {
            namespace: hash[:namespace],
            resource: hash[:resource],
            resource_param: hash[:resource_param],
            record_param: hash[:record_param],
            action: hash[:action].to_s.presence || "other",
            page: hash[:page]
          }
        end

        def gated_action(action)
          case action.to_s
          when "create" then "new"
          when "update" then "edit"
          else action.to_s
          end
        end

        def path_args_for(entry, context)
          return Array(entry[:path_args]) if entry.key?(:path_args)

          if entry[:scope].to_s == "member"
            record = context[:record_param]
            return [] if record.blank?

            return [record]
          end

          []
        end

        def interpolate(value, context)
          value.to_s
            .gsub("%{record_param}", context[:record_param].to_s)
            .gsub("%{resource}", context[:resource].to_s)
        end

        def append_query(url, query, context)
          return url if url.blank? || query.blank?

          pairs = query.filter_map do |key, value|
            interpolated = interpolate(value, context)
            next if interpolated.blank?

            [key.to_s, interpolated]
          end
          return url if pairs.empty?

          uri, fragment = url.to_s.split("#", 2)
          base, existing = uri.split("?", 2)
          merged = Rack::Utils.parse_nested_query(existing.to_s)
          pairs.each { |key, value| merged[key] = value }
          qs = merged.to_query
          built = qs.present? ? "#{base}?#{qs}" : base
          fragment.present? ? "#{built}##{fragment}" : built
        end

        def walk_menu(menu, view, parents: [])
          menu.items(view).flat_map do |item|
            label = item.label(view).to_s
            children = item.items(view).presence
            crumbs = parents + [label]

            if children
              walk_menu(item, view, parents: crumbs)
            elsif (url = item.url(view)).present?
              keywords = crumbs.map { |crumb| crumb.to_s.downcase.strip }.reject(&:blank?).uniq
              entry = {
                id: "nav-#{item.id}",
                kind: "navigate",
                label: crumbs.join(" › "),
                url: url,
                method: "get"
              }
              entry[:keywords] = keywords if keywords.any?
              [entry]
            else
              []
            end
          end
        end
      end
    end
  end
end
