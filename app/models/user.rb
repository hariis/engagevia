class User < ActiveRecord::Base

  acts_as_tagger
  has_many :posts
  has_many :comments
  has_many :engagements
  has_many :posts, :through => :engagements
  has_many :user_roles, :dependent => :destroy
  has_many :roles, :through => :user_roles

  acts_as_authentic do |c|
    c.login_field = :email
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

  def display_name
    activated? ? username : awesome_truncate(email, email.index('@'), "...")
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

end

