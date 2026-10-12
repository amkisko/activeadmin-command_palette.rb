# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user

  def current_user
    return @current_user if defined?(@current_user)

    @current_user = User.order(:id).first || User.create!(email: "dummy@example.com", name: "Dummy User")
  end

  def chat
    head :ok
  end
end
