# frozen_string_literal: true

Rails.application.routes.draw do
  get "/admin/chat", to: "application#chat", as: :admin_chat

  ActiveAdmin.routes(self)
end
