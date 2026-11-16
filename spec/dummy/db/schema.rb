# frozen_string_literal: true

ActiveRecord::Schema.define(version: 20_261_116_000_000) do
  create_table :active_admin_comments, force: :cascade do |t|
    t.string :namespace
    t.text :body
    t.string :resource_type
    t.bigint :resource_id
    t.string :author_type
    t.bigint :author_id
    t.timestamps
    t.index [:author_type, :author_id], name: "index_active_admin_comments_on_author"
    t.index [:namespace], name: "index_active_admin_comments_on_namespace"
    t.index [:resource_type, :resource_id], name: "index_active_admin_comments_on_resource"
  end

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
