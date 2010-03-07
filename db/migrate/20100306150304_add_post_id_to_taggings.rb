class AddPostIdToTaggings < ActiveRecord::Migration
  def self.up
    add_column :taggings, :post_id, :integer
  end

  def self.down
    remove_column :taggings, :post_id
  end
end
