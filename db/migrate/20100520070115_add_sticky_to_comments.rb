class AddStickyToComments < ActiveRecord::Migration
  def self.up
    add_column :comments, :sticky, :boolean, :default => 0
  end

  def self.down
    remove_column :comments, :sticky
  end
end
