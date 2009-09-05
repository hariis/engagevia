class Engagement < ActiveRecord::Base
  belongs_to :invitee, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post

  def self.get_followers(from_config)
     httpauth = Twitter::HTTPAuth.new(from_config[:twitid], from_config[:password])
     base = Twitter::Base.new(httpauth)

     base.followers if base
  end
end
