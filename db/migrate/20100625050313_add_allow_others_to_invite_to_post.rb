class AddAllowOthersToInviteToPost < ActiveRecord::Migration
  def self.up
    add_column :posts, :allow_others_to_invite, :boolean, :default => true
  end

  def self.down
     remove_column :posts, :allow_others_to_invite
  end
end


