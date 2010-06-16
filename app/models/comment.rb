class Comment < ActiveRecord::Base
  #after_create :update_contacts

  acts_as_tree
  named_scope :sticky, :conditions => {:sticky => 1}  , :order => 'updated_at desc'
  named_scope :top, lambda { { :conditions => "parent_id IS NULL AND sticky = 0", :order => 'updated_at desc' } }
  #named_scope :top, :conditions => {:parent_id => nil}  , :order => 'updated_at desc'
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post
  validates_presence_of :body
  after_save :touch_post

  def deliver_comment_notification(post)
    post.participants_to_notify.each do |participant|
     Notifier.deliver_comment_notification(post, self, participant)   if participant.id != owner.id
    end
  end
  def get_url_for_new_comment(post,user)
    DOMAIN + "comments/new" + "?pid=#{post.unique_id};uid=#{user.unique_id};pcid=#{id}"
  end

  def touch_post    
    post.update_attribute(:updated_at, self.updated_at)
  end
  
  def touch_root_parent_comment
    comment = self
    unless parent_id.nil?
      while comment.parent_id != nil
        comment = Comment.find(comment.parent_id)
      end    
      comment.update_attribute(:updated_at, self.updated_at)
    end
  end
  
end
