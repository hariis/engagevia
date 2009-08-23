class CreatePosts < ActiveRecord::Migration  
  def self.up
    create_table :posts , :force => true do |t|
      t.string :subject,      :null => false
      t.references :user
      t.string :url
      t.string :unique_id,    :null => false
      t.boolean :public,      :default => false
      t.text :note
      t.text :description

      t.timestamps
    end    
  end

  def self.down
    drop_table :posts
  end
end
