class CreateEngagements < ActiveRecord::Migration
  def self.up
    create_table :engagements do |t|
      t.references :user
      t.references :post
      t.integer :invited_by
      t.datetime :invited_when

      t.timestamps
    end
  end

  def self.down
    drop_table :engagements
  end
end
