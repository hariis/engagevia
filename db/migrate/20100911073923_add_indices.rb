class AddIndices < ActiveRecord::Migration
  def self.up
    add_index :users, :unique_id, :unique => true
    add_index :posts, :unique_id, :unique => true
    add_index :engagements, :post_id
    add_index :comments, :user_id
    add_index :comments, :sticky
    add_index :groups, :name
    add_index :groups, :user_id
    add_index :memberships, :group_id
    add_index :memberships, :user_id
    add_index :shared_posts, :post_id
    add_index :shared_posts, :user_id
  end

  def self.down
    remove_index :users, :unique_id, :unique => true
    remove_index :posts, :unique_id, :unique => true
    remove_index :engagements, :post_id
    remove_index :comments, :user_id
    remove_index :comments, :sticky
    remove_index :groups, :name
    remove_index :groups, :user_id
    remove_index :memberships, :group_id
    remove_index :memberships, :user_id
    remove_index :shared_posts, :post_id
    remove_index :shared_posts, :user_id
  end
end
