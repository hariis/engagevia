class Comment < ActiveRecord::Base
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post
  validates_presence_of :body
end
