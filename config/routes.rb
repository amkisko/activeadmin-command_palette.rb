# frozen_string_literal: true

ActiveAdmin::CommandPalette::Engine.routes.draw do
  scope module: "active_admin/command_palette" do
    match "options", to: "options#index", as: :options, via: [:get, :post]
  end
end
