class AddEngagementsInvitedVia < ActiveRecord::Migration
  def self.up
       add_column :engagements, :invited_via, :string, :default => "email", :null => false

  end

  def self.down
     remove_column :engagements, :invited_via
  end
end
