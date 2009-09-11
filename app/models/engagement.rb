class Engagement < ActiveRecord::Base
  belongs_to :invitee, :class_name => 'User', :foreign_key => :user_id
  belongs_to :post

  def self.get_followers(from_config)

     begin
         get_followers_safe(from_config)

     rescue Exception => e
        logger.info e
        raise $! # rethrow     
     end
  end
  
  private
  def self.get_followers_safe(from_config)
     httpauth = Twitter::HTTPAuth.new(from_config[:twitid], from_config[:password])
          1.upto(3).each do
              base = Twitter::Base.new(httpauth)
               #check if we got the right response object
               return base.followers if base && base.followers.first.screen_name != nil
         end
         raise
  end
end
