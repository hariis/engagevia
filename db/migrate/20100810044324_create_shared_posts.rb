class CreateSharedPosts < ActiveRecord::Migration
  def self.up
    create_table :shared_posts, :force => true do |t|
      t.references :user
      t.references :post
      t.integer :shared_by,    :null => false
      t.datetime :shared_when, :null => false
      t.boolean :notify_me, :default => true
      t.timestamps
    end
      add_index   :shared_posts, :shared_by
  end

  def self.down
    drop_table :shared_posts
  end
end
