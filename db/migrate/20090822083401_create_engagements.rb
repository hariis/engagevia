class CreateEngagements < ActiveRecord::Migration  
  def self.up
    create_table :engagements, :force => true do |t|
      t.references :user
      t.references :post
      t.integer :invited_by,    :null => false
      t.datetime :invited_when, :null => false

      t.timestamps
    end
      add_index   :engagements, :invited_by
  end

  def self.down
    drop_table :engagements
  end
end
