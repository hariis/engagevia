class SharedPost < ActiveRecord::Base
  belongs_to :invitee, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post
end
