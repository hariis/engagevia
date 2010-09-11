class CreateUsers < ActiveRecord::Migration
  def self.up
    create_table :users, :options => "auto_increment = 1000" do |t|
      t.string :username,          :null => false
      t.string :email,             :null => false
      t.string :crypted_password,  :null => false
      t.string :password_salt,     :null => false
      t.string :persistence_token, :null => false
      t.datetime :activated_at
      t.string :time_zone
      t.datetime  :current_login_at
      t.datetime  :last_login_at
      t.datetime  :last_request_at
      t.string :unique_id
      t.timestamps
    end
    add_index :users, :email
    add_index :users, :unique_id, :unique => true
  end

  def self.down
    drop_table :users
  end
end
