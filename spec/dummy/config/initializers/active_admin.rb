# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.authentication_method = :authenticate_admin_user!
  config.current_user_method = :current_user
  config.site_title = "Dummy"
  config.logout_link_path = false

  config.namespace :admin do |admin|
    admin.graphql = true
  end
end

# Stimulus boot for system specs: ActiveAdmin.importmap entry loads AA JS then
# registers the command palette controller (host apps do the same via their layout).
ActiveAdmin.importmap.draw do
  pin "@hotwired/stimulus", to: "stimulus.min.js"
  pin "active_admin_palette_boot", to: "active_admin_palette_boot.js"
end

ActiveAdmin::CommandPalette.configure do |config|
  config.default_finder = lambda { |registration:, query:, helpers:, user:, limit:|
    # Dummy app has no authorization library. Production hosts must start from the
    # same policy scope as the ActiveAdmin resource (for example accessible_by or
    # policy_scope), never bare .all for role- or tenant-limited data.
    scope = registration.resource_class.all
    if registration.find_columns.any?
      conditions = registration.find_columns.map { |column| "#{column} LIKE ?" }
      values = Array.new(registration.find_columns.size) { "%#{query}%" }
      scope = scope.where(conditions.join(" OR "), *values)
    end
    scope = scope.order(registration.order_column) if registration.order_column
    scope.limit(limit).map do |record|
      label = record.public_send(registration.label_method)
      row = {
        id: record.id,
        kind: registration.kind,
        label: label,
        url: helpers.public_send(registration.show_path, record)
      }
      if record.respond_to?(:email) && record.email.present? && record.email != label
        row[:detail] = record.email
      end
      row
    end
  }
end
