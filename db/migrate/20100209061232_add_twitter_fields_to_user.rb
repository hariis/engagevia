class AddTwitterFieldsToUser < ActiveRecord::Migration
  def self.up
    add_column :users, :screen_name,    :string, :default => ""
    add_column :users, :token,    :string, :default => ""
    add_column :users, :secret,    :string, :default => ""
  end

  def self.down
    remove_column :users, :screen_name
    remove_column :users, :token
    remove_column :users, :secret
  end
end
