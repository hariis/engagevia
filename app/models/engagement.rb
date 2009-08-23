class Engagement < ActiveRecord::Base
  belongs_to :invitee, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post

  def self.send_twitter_notification(from_config,followers)

   httpauth = Twitter::HTTPAuth.new(from_config[:twitid], from_config[:password])
   base = Twitter::Base.new(httpauth)
   followers.each do |friend|
      base.update "d #{friend}" + " You are invited to join a conversation. Please check your email for details."
    end
  end

  def self.get_followers(from_config)

   httpauth = Twitter::HTTPAuth.new(from_config[:twitid], from_config[:password])
   base = Twitter::Base.new(httpauth)
   followers = []
    base.followers.each do |friend|
      followers << friend.screen_name
    end
  end
end
