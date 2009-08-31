class Comment < ActiveRecord::Base
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post
  validates_presence_of :body

  def deliver_comment_notification(post)
    post.participants.each {|participant| Notifier.deliver_comment_notification(post, self, participant)}
  end

end
