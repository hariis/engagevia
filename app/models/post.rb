class Post < ActiveRecord::Base
  require 'rubygems'
  require 'twitter'
  acts_as_taggable
  
  has_many :comments, :dependent => :destroy
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  has_many :engagements, :dependent => :destroy
  has_many :shared_posts, :dependent => :destroy
  has_many :participants, :through => :engagements, :source => :invitee, :class_name => 'User', :foreign_key => :user_id
  has_many :potential_participants, :through => :shared_posts, :source => :invitee, :class_name => 'User', :foreign_key => :user_id
  has_many :participants_to_notify, :through => :engagements, :source => :invitee, :class_name => 'User', :foreign_key => :user_id,
           :conditions => 'engagements.notify_me = 1'
  has_attached_file :avatar, :styles => { :medium => "300x300>" }
  validates_presence_of :subject
  validates_attachment_size :avatar, :less_than => 5.megabytes
  validates_attachment_content_type :avatar, :content_type => ['image/jpeg', 'image/png']
  after_create :send_post_link

  def send_post_link      
      Notifier.deliver_post_link(self)
      eng = Engagement.new
      eng.invited_by = self.owner.id  #TODO Shoudl this be 0 ?
      eng.invited_when = Time.now.utc
      eng.post = self
      eng.invitee = self.owner
      eng.joined = true
      eng.save
  end
  def self.generate_unique_id
    ActiveSupport::SecureRandom.hex(20)
  end

  def self.get_invitees(invitees_emails)
    invitees = []
    invitees_emails.each_pair do |email,name|
      user = User.find_by_email(email)
      user = User.create_non_member(email,name[0],name[1]) if user.nil?
      invitees << user unless user.nil?
    end
    return invitees
  end
  
  def self.get_twitter_invitees(followers)
    invitees = []
    followers.each do |follower|
      user = User.find_by_screen_name(follower)
      if user.nil?
        user = User.create_non_member_by_twitter_id(follower)
      end
      invitees << user
    end
    return invitees
  end

  def send_invitations(invitees,inviter)
    invitees.each_key{|invitee| Notifier.deliver_send_invitations(self, invitee,inviter)}
  end
#  def send_twitter_notification(followers)
#   httpauth = Twitter::HTTPAuth.new(from_config[:twitid], from_config[:password])
#   base = Twitter::Base.new(httpauth)
#   followers.each_key do |follower|
#      message = DOMAIN + "conversation/show/#{self.unique_id}/#{follower.unique_id}"
#      base.update "d #{follower.username}" + " Join me for a conversation. The link is at " + message
#   end
#  end

  def get_url_for(user,action)
    if action == 'show'
      DOMAIN + "posts/" + action + "?pid=#{self.unique_id}&uid=#{user.unique_id}"

    elsif action == 'send_invites' 
      DOMAIN + "engagements/" + action + "?post_id=#{self.id};uid=#{user.unique_id}"
    elsif action == 'share_open_invites'
      DOMAIN + "shared_posts/" + action + "?post_id=#{self.id};uid=#{user.unique_id}"    
    elsif action == 'dlg_join_conversation'
      DOMAIN + "engagements/" + action + "?post_id=#{self.id};iid=#{user.unique_id}"
    end
  end
  def get_readonly_url(inviter)
    DOMAIN + "posts/show" + "?pid=#{self.unique_id}&iid=#{inviter.unique_id}"
  end
  def get_fb_auth_url
    DOMAIN + "authorize"
  end
  def get_all_participants
    p = []
    self.engagements.each do |engagement|
      p << engagement.invitee
    end
    return p
  end
  
  def get_all_member_participants_for_display
    m = []
    get_all_participants.each do |p|
      m << p if p.member?
    end
    for_display = ""
    if m.size > 0
      for_display = m[0].first_name
    end
    if m.size > 1
      for_display += (" and " + m[1].first_name )
    end

    for_display += m.size > 1 ? " are members " : " is a member "
    for_display += "of EngageVia"
    
    return for_display
  end
  def unread_comments_for(user)
    unread = 0
    comments.each do |comment|
       if comment.owner != user && comment.updated_at > last_viewed_at(user)
         unread = unread + 1
       end
    end
    return unread
  end
  def last_viewed_at(user)
    eng = user.engagements.find_by_post_id(id)
    return eng.last_viewed_at ? eng.last_viewed_at : Time.parse( "5/14" )
  end

  def notification_status
    #get one engagement of the post and return its status
    unless engagements.empty?
        engagements[0].notify_me?
    end
  end

  def is_first_comment?(user)
    comments_by_user = comments.find(:all, :conditions => ['user_id = ?',user.id])
    return comments_by_user.count == 1 unless comments_by_user.nil?
    return false
  end

  def comments_by(user)
    total = 0
    comments_by_user = comments.find(:all, :conditions => ['user_id = ?',user.id])
    total = comments_by_user.size unless comments_by_user.nil?
    return total
  end
end
