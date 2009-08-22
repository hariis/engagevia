class Notifier < ActionMailer::Base
  
default_url_options[:host] = "li98-245.members.linode.com/"

  def password_reset_instructions(user)
    subject       "Password Reset Instructions"
    from          "EngageVia Notifier <noreply@li98-245.members.linode.com/>"
    recipients    user.email
    sent_on       Time.zone.now
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end
 
  def deliver_notify_invitees(user)
    subject       "EngageVia | New Venue(s) added"
    from          "EngageVia Notifier <noreply@li98-245.members.linode.com>"
    recipients    user.email
    sent_on       Time.zone.now
    body             :user => user
  end

  protected
    def setup_email(user)
      @recipients  = "#{venue.emails}"
      @from        = "EngageVia <yeeyay-notifier@li98-245.members.linode.com>"
      headers         "Reply-to" => "EngageVia-notifier@li98-245.members.linode.com"
      @subject     = "[EngageVia] "
      @sent_on     = Time.zone.now
      @content_type = "text/html"
    end
end
