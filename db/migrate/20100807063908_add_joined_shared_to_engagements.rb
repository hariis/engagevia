class AddJoinedSharedToEngagements < ActiveRecord::Migration
  def self.up
    add_column :engagements, :joined, :boolean, :default => false
    add_column :engagements, :shared, :boolean, :default => false
  end

  def self.down
     remove_column :engagements, :joined
     remove_column :engagements, :shared
  end
end
