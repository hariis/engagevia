class AddRoles < ActiveRecord::Migration
    def self.up
      create_table :roles,:force => true do |t|
        t.column :name, :string
      end

      add_index :roles, :name
      Role.create(:name => "admin")
      Role.create(:name => "private_beta_tester")
      Role.create(:name => "public_beta_tester")
      Role.create(:name => "rails_rumble_beta_tester")
      Role.create(:name => "member")
      Role.create(:name => "non_member")

    end

    def self.down
      drop_table :roles
    end
end
