class AddSharedViaToSharedPosts < ActiveRecord::Migration
  def self.up
    add_column :shared_posts, :shared_via, :string, :null => false
  end

  def self.down
    remove_column :shared_posts, :shared_via
  end
end