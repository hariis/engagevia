class Post < ActiveRecord::Base
  require 'rubygems'
  require 'twitter'
  acts_as_taggable
  
  has_many :comments, :dependent => :destroy
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  has_many :engagements, :dependent => :destroy
  has_many :participants, :through => :engagements, :source => :invitee, :class_name => 'User', :foreign_key => :user_id
  has_many :notify_participants, :through => :engagements, :source => :invitee, :class_name => 'User',
           :conditions => 'engagements.notify_comment = 1'

  validates_presence_of :subject

  after_create :send_post_link

  def send_post_link
      #send an email with confirmation link
      Notifier.deliver_post_link(self)    
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
      invitees << user
    end
    return invitees
  end
  
  def self.get_twitter_invitees(followers)
    invitees = []
    followers.each do |follower|
      user = User.find_by_username(follower)
      if user.nil?
        user = User.create_non_member_by_twitter_id(follower)
      end
      invitees << user
    end
    return invitees
  end

  def send_invitations(invitees)
    invitees.each{|invitee| Notifier.deliver_send_invitations(self, invitee)}
  end
  def send_twitter_notification(from_config,followers)
   httpauth = Twitter::HTTPAuth.new(from_config[:twitid], from_config[:password])
   base = Twitter::Base.new(httpauth)
   followers.each do |follower|
      message = DOMAIN + "conversation/show/#{self.unique_id}/#{follower.unique_id}"
      base.update "d #{follower.username}" + " You are invited to join a conversation. The link is at " + message
   end
  end

  def get_url_for(user)
    DOMAIN + "posts/show?pid=#{self.unique_id};uid=#{user.unique_id}"
  end
end
