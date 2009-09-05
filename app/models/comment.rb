class Comment < ActiveRecord::Base
  acts_as_tree
  
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post
  validates_presence_of :body

  def deliver_comment_notification(post)
    post.participants_to_notify.each do |participant|
     Notifier.deliver_comment_notification(post, self, participant)     
    end
  end
end
