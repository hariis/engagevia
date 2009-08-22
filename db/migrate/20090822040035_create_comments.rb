class CreateComments < ActiveRecord::Migration
  def self.up
    create_table :comments do |t|
      t.references :user
      t.references :post
      t.text :body,          :null => false
      t.integer :parent_id,  :null => false

      t.timestamps
    end

    add_index :comments, :parent_id
  end

  def self.down
    drop_table :comments
  end
end
