# frozen_string_literal: true

module ActiveAdmin
  module CommandPalette
    class Compiler
      Registration = Struct.new(
        :kind,
        :noun,
        :resource_name,
        :resource_class,
        :find_columns,
        :label_method,
        :order_column,
        :show_path,
        :new_path,
        :edit_path
      )

      class << self
        def compile
          actions = []
          finders = []

          each_resource do |resource|
            palette = resource.command_palette_config
            next unless palette.enabled?

            registration = build_registration(resource, palette)
            actions.concat(standard_actions_for(registration, palette))
            actions.concat(member_actions_for(registration, palette))
            finders << registration if registration.find_columns.any?
          end

          {actions: actions, finders: finders}
        end

        private

        def each_resource
          return unless defined?(ActiveAdmin) && ActiveAdmin.application

          ActiveAdmin.application.namespaces.each do |namespace|
            namespace.resources.each do |resource|
              next unless resource.is_a?(ActiveAdmin::Resource)
              next unless resource.respond_to?(:command_palette_config)

              yield resource
            end
          end
        end

        def build_registration(resource, palette)
          namespace = resource.namespace.name.to_s
          singular = resource.resource_name.singular
          kind = palette.kind.presence || resource.resource_class.name.demodulize.underscore
          noun = palette.noun.presence || kind.tr("_", " ")

          Registration.new(
            kind: kind,
            noun: noun,
            resource_name: resource.resource_class.name.demodulize,
            resource_class: resource.resource_class,
            find_columns: palette.find_columns,
            label_method: palette.label_method,
            order_column: palette.order_column,
            show_path: :"#{namespace}_#{singular}_path",
            new_path: :"new_#{namespace}_#{singular}_path",
            edit_path: :"edit_#{namespace}_#{singular}_path"
          )
        end

        def standard_actions_for(registration, palette)
          actions = []
          noun = registration.noun
          kind = registration.kind
          resource = registration.resource_name

          if palette.standard_actions.include?(:view)
            actions << {
              id: "view-#{kind.tr("_", "-")}",
              label: "View #{noun}",
              verb: "view",
              finder_kind: kind,
              scope: "global",
              when: "any",
              help: "View #{noun} — type a search term"
            }
          end

          if palette.standard_actions.include?(:create)
            entry = {
              id: "create-#{kind.tr("_", "-")}",
              label: "Create #{noun}",
              verb: "create",
              path: registration.new_path,
              scope: "global",
              when: "any",
              help: palette.create_help.presence || "Create #{noun}"
            }
            entry[:params] = palette.create_params if palette.create_params.any?
            actions << entry
          end

          if palette.standard_actions.include?(:edit)
            actions << {
              id: "edit-#{kind.tr("_", "-")}",
              label: "Edit #{noun}",
              verb: "edit",
              path: registration.edit_path,
              scope: "member",
              when: "show",
              resource: resource
            }
          end

          if palette.standard_actions.include?(:destroy)
            actions << {
              id: "delete-#{kind.tr("_", "-")}",
              label: "Delete #{noun}",
              verb: "destroy",
              path: registration.show_path,
              method: "delete",
              confirm: "Delete this #{noun}?",
              scope: "member",
              when: "show",
              resource: resource
            }
          end

          actions
        end

        def member_actions_for(registration, palette)
          palette.members.map do |member|
            id = member[:id].presence || "#{member[:label].to_s.parameterize}-#{registration.kind.tr("_", "-")}"
            entry = {
              id: id,
              label: member[:label],
              scope: member.fetch(:scope, "member"),
              when: member.fetch(:when, "show"),
              resource: registration.resource_name,
              method: member[:method] || "get",
              confirm: member[:confirm],
              path: member[:path],
              url: member[:url],
              path_args: member.key?(:path_args) ? member[:path_args] : nil,
              query: member[:query],
              verb: member[:verb] || "custom",
              if: member.key?(:if) ? member[:if] : nil
            }
            entry.delete(:path_args) if entry[:path_args].nil?
            entry.delete(:if) unless member.key?(:if)
            entry.compact
          end
        end
      end
    end
  end
end
