# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_261_009_000_000) do
  create_table :users, force: :cascade do |t|
    t.string :email
    t.string :name
    t.timestamps
  end

  create_table :articles, force: :cascade do |t|
    t.string :title
    t.string :status
    t.timestamps
  end
end
