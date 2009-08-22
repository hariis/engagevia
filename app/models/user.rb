class User < ActiveRecord::Base

  has_many :posts, :through => :engagements
  has_many :comments
  has_many :engagements


  acts_as_authentic do |c|
    #c.login_field = :email

  end

  def deliver_password_reset_instructions!
    reset_perishable_token!
    #Notifier.deliver_password_reset_instructions(self)
  end

  def deliver_account_confirmation_instructions!
    reset_perishable_token!
    #Notifier.deliver_account_confirmation_instructions(self)
  end

end

