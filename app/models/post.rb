class Post < ActiveRecord::Base
  require 'rubygems'
  require 'twitter'
  acts_as_taggable
  
  has_many :comments, :dependent => :destroy
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  has_many :engagements, :dependent => :destroy
  has_many :participants, :through => :engagements, :source => :invitee, :class_name => 'User', :foreign_key => :user_id

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

  def send_invitations(invitees)
    invitees.each{|invitee| Notifier.deliver_send_invitations(self, invitee)}
  end

end
