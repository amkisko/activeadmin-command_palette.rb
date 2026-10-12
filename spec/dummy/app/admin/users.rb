# frozen_string_literal: true

ActiveAdmin.register User do
  menu false

  command_palette do
    kind "user"
    noun "user"
    label_method :name_or_email
    find_by :email, :name
    order :name
    actions :view, :create, :edit, :destroy
    create help: "Create user — optional email=", params: [
      {name: "email", required: false, help: "Email", query_key: "user[email]"}
    ]
    member "Open in chat",
      id: "open-chat-user",
      path: :admin_chat_path,
      path_args: [],
      query: {context_selector: "user:%{record_param}"}
  end

  permit_params :email, :name
end
