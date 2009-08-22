class CreateEngagements < ActiveRecord::Migration
  def self.up
    create_table :engagements do |t|
      t.references :invitee
      t.references :post
      t.integer :invited_by,    :null => false
      t.datetime :invited_when, :null => false

      t.timestamps
    end
      add_index   :engagements, :invited_by
      foreign_key :engagements, :invitee, :users
  end

  def self.down
    drop_table :engagements
  end
end
