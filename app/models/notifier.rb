class Notifier < ActionMailer::Base
  
default_url_options[:host] = "li98-245.members.linode.com/"

  def password_reset_instructions(user)
    @subject    +=   " Password Reset Instructions"
    recipients    user.email
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end
 
  def account_confirmation_instructions(user)
    setup_email(user)
    @subject    += ' Please activate your new account'
    recipients    user.email
    
    body          :activation_url  => DOMAIN + "activate/#{user.perishable_token}"
  end

  def confirm_activation(user)
    setup_email(user)
    subject    += 'Woohoo! Your account has been activated!'
    body       :url  => DOMAIN
  end

  protected
    def setup_email(user)      
      @from        = "EngageVia <yeeyay-notifier@li98-245.members.linode.com>"
      headers         "Reply-to" => "EngageVia-notifier@li98-245.members.linode.com"
      @subject     = "[EngageVia] "
      @sent_on     = Time.zone.now
      @content_type = "text/html"
    end
end
