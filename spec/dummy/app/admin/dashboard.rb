# frozen_string_literal: true

ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: "Dashboard"

  content do
    para "Dummy dashboard"
  end
end
