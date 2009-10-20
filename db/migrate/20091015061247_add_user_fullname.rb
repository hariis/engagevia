class AddUserFullname < ActiveRecord::Migration
  def self.up
     add_column :users, :first_name,    :string, :default => "", :null => false
     add_column :users, :last_name,     :string, :default => "", :null => false
     add_column :users, :facebook_link, :string
     add_column :users, :linked_in_link, :string
     add_column :users, :blog_link,     :string
  end

  def self.down
    remove_column :users, :first_name
    remove_column :users, :last_name
    remove_column :users, :facebook_link
    remove_column :users, :linked_in_link
    remove_column :users, :blog_link
  end
end
