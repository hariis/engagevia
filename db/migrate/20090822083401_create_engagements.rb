require "migration_helpers"
class CreateEngagements < ActiveRecord::Migration
  extend MigrationHelpers
  def self.up
    create_table :engagements do |t|
      t.integer :invitee
      t.references :post
      t.integer :invited_by,    :null => false
      t.datetime :invited_when, :null => false

      t.timestamps
    end
      add_index   :engagements, :invited_by
      add_index   :engagements, :invitee
      foreign_key :engagements, :invitee, :users
  end

  def self.down
    drop_table :engagements
  end
end
