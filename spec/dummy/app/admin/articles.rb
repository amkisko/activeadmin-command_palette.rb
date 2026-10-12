# frozen_string_literal: true

ActiveAdmin.register Article do
  menu false

  command_palette do
    kind "article"
    noun "article"
    label_method :title
    find_by :title
    order :title
    actions :view, :create, :edit
  end

  permit_params :title, :status
end
