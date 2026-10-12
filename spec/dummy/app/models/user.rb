# frozen_string_literal: true

class User < ApplicationRecord
  def name_or_email
    name.presence || email
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at email name updated_at]
  end
end
