class AddUserRoles < ActiveRecord::Migration
    def self.up
       create_table :user_roles,:force => true do |t|
        t.column :user_id, :integer
        t.column :role_id, :integer
        t.column :created_at, :datetime
      end

     end

    def self.down
      drop_table :user_roles
    end
end