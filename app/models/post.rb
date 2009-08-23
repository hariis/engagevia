class Post < ActiveRecord::Base
  require 'rubygems'
  require 'twitter'
  acts_as_taggable
  
  has_many :comments, :dependent => :destroy
  belongs_to :owner, :class_name => 'User', :foreign_key => :user_id
  
  has_many :engagements, :dependent => :destroy
  has_many :participants, :through => :engagements, :source => :invitee

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
        user = User.new
        user.username = 'nonmember'
        user.email = email
        user.password = 'mounthood'
        user.password_confirmation = 'mounthood'
       
        user.save
      end
      invitees << user
    end
    return invitees
  end

  def send_invitations(invitees_emails)
    invitees_emails.each{|email| Notifier.deliver_send_invitations(self, email)}
  end

end
