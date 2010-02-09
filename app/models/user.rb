class User < ActiveRecord::Base
  require 'digest/md5'
  acts_as_tagger
  has_attached_file :avatar, :styles => { :medium => "300x300>", :thumb => "32x32>" }
  has_many :posts
  has_many :comments
  has_many :engagements
  has_many :posts, :through => :engagements
  has_many :user_roles, :dependent => :destroy
  has_many :roles, :through => :user_roles

  validates_presence_of :first_name, :last_name

  validates_attachment_size :avatar, :less_than => 500.kilobytes
  validates_attachment_content_type :avatar, :content_type => ['image/jpeg', 'image/png']
  acts_as_authentic do |c|
    c.login_field = :email
  end
  before_create :assign_unique_id

  def assign_unique_id
    if email.slice(0..8) != "nonmember"
      self.unique_id = Digest::MD5.hexdigest(email + "Mount^Hood")
    elsif username.size > 0
      self.unique_id = Digest::MD5.hexdigest(username + "Mount^Hood")
    end
    
  end
  def deliver_password_reset_instructions!
    reset_perishable_token!
    Notifier.deliver_password_reset_instructions(self)
  end

  def deliver_account_confirmation_instructions!
    reset_perishable_token!
    Notifier.deliver_account_confirmation_instructions(self)
  end

  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :password, :password_confirmation, :time_zone

  def has_role?(role)
    self.roles.count(:conditions => ["name = ?", role]) > 0
  end

	def add_role(role)
	  return if self.has_role?(role)
	  self.roles << Role.find_by_name(role)
	end

  # Activates the user in the database.
  def activate
    self.activated_at = Time.now.utc
    self.perishable_token = nil
    save(false)
  end

  def activated?
    #!! perishable_token.nil?
    !activated_at.nil?
  end

  def member?
    has_role?("member")
  end

  def non_member?
    has_role?("non_member")
  end

  def admin?
    has_role?("admin")
  end

  def self.create_non_member(email)
    user = User.new
    user.username = 'nonmember'
    user.email = email
    user.password = 'mounthood'
    user.password_confirmation = 'mounthood'
    user.add_role("non_member")
    user.first_name = "firstname"
    user.last_name = "lastname"
    if user.save
      return user
    end
  end

  def self.create_non_member_by_twitter_id(follower_screen_name)
    user = User.new
    user.username = follower_screen_name
    user.email = "nonmember@nonmember.com"    
    user.password = 'mounthood'
    user.password_confirmation = 'mounthood'
    user.add_role("non_member")
    user.first_name = "firstname"
    user.last_name = "lastname"
    user.save(false)
    return user
  end
  
  def display_name(post=nil,engagement=nil)    
      if member? #whether activated or not - as long as they signed up, we have their email id and or twitter id
        return first_name.titleize + " " + last_name.titleize
        #Make a judgment based on how the person got invited
        #return get_display_name_via_engagement_or_post(post,engagement) if (post || engagement)
      elsif (post || engagement) #If not a member, check how he/she got invited
        #In case they have entered their first name, display that
        if first_name != 'firstname' && last_name != 'last_name'
          return first_name.titleize + " " + last_name.titleize
        else
          return get_display_name_via_engagement_or_post(post,engagement) if (post || engagement)
        end
      end
      #Last resort
        #In case they have entered their first name, display that
        if first_name != 'firstname' && last_name != 'last_name'
          return first_name.titleize + " " + last_name.titleize
        else
          return get_email_name  #currently used by layout
        end
      
  end
  def get_display_name_via_engagement_or_post(post=nil,engagement=nil)
    if engagement
      return get_display_name_via_engagement(engagement)
    end
    if post
      eng = Engagement.find(:first, :conditions => ['user_id = ? and post_id = ?',id, post.id])
      return get_display_name_via_engagement(eng)
    end
  end
  def get_display_name_via_engagement(engagement)
    if engagement
      if engagement.invited_via == 'twitter'
        get_twitter_name
      else
        get_email_name
      end
    end
  end
  def get_email_name
    awesome_truncate(email, email.index('@'), "")
  end
  def get_twitter_name
    "@" + username
  end
  # Awesome truncate
  # First regex truncates to the length, plus the rest of that word, if any.
  # Second regex removes any trailing whitespace or punctuation (except ;).
  # Unlike the regular truncate method, this avoids the problem with cutting
  # in the middle of an entity ex.: truncate("this &amp; that",9)  => "this &am..."
  # though it will not be the exact length.
  def awesome_truncate(text, length = 30, truncate_string = "...")
    return if text.nil?
    l = length - truncate_string.mb_chars.length
    text.mb_chars.length > length ? text[/\A.{#{l}}\w*\;?/m][/.*[\w\;]/m] + truncate_string : text
  end

  def twitter_id
    (username != "" && username != 'nonmember' ) ? username : ""
  end

  def self.consumer
     OAuth::Consumer.new("2ABzvtWhFUCZFiluhc7bGg","byf0AI0N6iazhGK1AeZWOqmaOZzm0cKvsMmnu8uDIM",{:site => "http://twitter.com"})
  end
end

