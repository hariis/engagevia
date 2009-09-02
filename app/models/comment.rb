class Comment < ActiveRecord::Base
  acts_as_tree
  
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post
  validates_presence_of :body

  def deliver_comment_notification(post)
    post.notify_participants.each do |participant|
      #if (participant.notify_comment?)
        Notifier.deliver_comment_notification(post, self, participant)
      #end
    end
  end
end
