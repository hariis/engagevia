class Post < ActiveRecord::Base
  require 'rubygems'
  require 'twitter'

  has_many :comments, :dependent => true
  belongs_to :owner , :class_name => 'User', :foreign_key => :user_id
  
  has_many :engagements, :dependent => true
  has_many :participants, :through => :engagements, :source => :user, :dependent => true

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
        user = User.create(:username => 'nonmember',:email => email, :password => 'mounthood', :password_confirmation => 'mounthood')
      end
      invitees << user
    end
  end

  def self.send_invitations(invitees_emails)
    invitees_emails.each{|email| Notifier.deliver_send_invitations(self, email)}
  end
end
