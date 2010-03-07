class Post < ActiveRecord::Base
  require 'rubygems'
  require 'twitter'
  acts_as_taggable
  
  has_many :comments, :dependent => :destroy
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  has_many :engagements, :dependent => :destroy
  has_many :participants, :through => :engagements, :source => :invitee, :class_name => 'User', :foreign_key => :user_id
  has_many :participants_to_notify, :through => :engagements, :source => :invitee, :class_name => 'User', :foreign_key => :user_id,
           :conditions => 'engagements.notify_me = 1'

  validates_presence_of :subject

  after_create :send_post_link

  def send_post_link      
      Notifier.deliver_post_link(self)
      eng = Engagement.new
      eng.invited_by = self.owner.id  #TODO Shoudl this be 0 ?
      eng.invited_when = Time.now.utc
      eng.post = self
      eng.invitee = self.owner
      eng.save
  end
  def self.generate_unique_id
    ActiveSupport::SecureRandom.hex(20)
  end

  def self.get_invitees(invitees_emails)
    invitees = []
    invitees_emails.each do |email|
      user = User.find_by_email(email)
      if user.nil?
        user = User.create_non_member(email)
      end
      invitees << user if !user.nil?
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
      DOMAIN + "posts/" + action + "?pid=#{self.unique_id};uid=#{user.unique_id}"
  end

  def get_all_participants
    p = []
    self.engagements.each do |engagement|
      p << engagement.invitee
    end
    return p
  end
end
