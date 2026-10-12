# frozen_string_literal: true

Rails.application.routes.draw do
  get "/admin/chat", to: "application#chat", as: :admin_chat

  mount ActiveAdmin::CommandPalette::Engine => "/admin/command_palette", :as => "active_admin_command_palette"
  ActiveAdmin.routes(self)
end
