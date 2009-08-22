class CreatePosts < ActiveRecord::Migration
  def self.up
    create_table :posts do |t|
      t.string :subject
      t.integer :created_by
      t.string :url
      t.string :unique_id
      t.boolean :privacy
      t.text :note
      t.text :description

      t.timestamps
    end
  end

  def self.down
    drop_table :posts
  end
end
