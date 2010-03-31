class UserRole < ActiveRecord::Base
  belongs_to :role
  belongs_to :user
  named_scope :admins, :conditions => { :role_id => 1 }

  def self.get_admin_user
     User.find_by_id(1027)
#    admins.each do |a|
#       u = User.find(a.user_id)
#       return u if u.username == 'engagevia'
#    end
  end
end
