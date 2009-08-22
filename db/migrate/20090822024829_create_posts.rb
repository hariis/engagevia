require "migration_helpers"
class CreatePosts < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :posts do |t|
      t.string :subject,      :null => false
      t.integer :created_by,  :null => false
      t.string :url
      t.string :unique_id,    :null => false
      t.boolean :public,      :default => false
      t.text :note
      t.text :description
      t.datetime :validated_at

      t.timestamps
    end

    add_index :posts, :created_by
    foreign_key :posts, :created_by, :users
  end

  def self.down
    drop_table :posts
  end
end
