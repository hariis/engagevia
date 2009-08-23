class Post < ActiveRecord::Base
  require 'rubygems'
  require 'twitter'

  has_many :comments
  belongs_to :owner , :class_name => 'User', :foreign_key => :user_id
  
  has_many :engagements
  has_many :participants, :through => :engagements, :source => :user

  
  
  def self.get_unique_id
        12345
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
end
