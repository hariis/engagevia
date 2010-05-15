class AddLastViewedAtToEngagements < ActiveRecord::Migration
  def self.up
    add_column :engagements, :last_viewed_at, :datetime
  end

  def self.down
    remove_column :engagements, :last_viewed_at
  end
end


