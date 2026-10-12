# frozen_string_literal: true

ActiveAdmin.setup do |config|
  config.authentication_method = false
  config.current_user_method = :current_user
  config.site_title = "Dummy"
  config.logout_link_path = false
end

ActiveAdmin::CommandPalette.configure do |config|
  config.authorize_with = ->(controller) { controller.current_user.present? }
  config.default_finder = lambda { |registration:, query:, helpers:, user:, limit:|
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
