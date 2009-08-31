class AddEngagementsNotifyCommentField < ActiveRecord::Migration
  def self.up
    add_column :engagements, :notify_comment, :boolean, :default => true
  end

  def self.down
    remove_column :engagements, :notify_comment
  end
end