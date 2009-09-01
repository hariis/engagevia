class Notifier < ActionMailer::Base

default_url_options[:host] = "li98-245.members.linode.com"

  def password_reset_instructions(user)
    setup_email(user)
    @subject    +=   " Password Reset Instructions"
    recipients    user.email
    body          :edit_password_reset_url => edit_password_reset_url(user.perishable_token)
  end
 
  def account_confirmation_instructions(user)
    setup_email(user)
    @subject    += ' Please activate your new account'
    recipients    user.email
    
    body          :activation_url  => DOMAIN + "users/activate/#{user.perishable_token}"
  end

  def confirm_activation(user)
    setup_email(user)
    subject    += 'Woohoo! Your account has been activated!'
    body       :url  => DOMAIN
  end

  def post_link(post)
    setup_email(post.owner)
    @subject    += ' Location of your new Posting'
    recipients    post.owner.email
    
    body          :post_url  => DOMAIN + "conversation/show/#{post.unique_id}/#{post.owner.unique_id}" , :post => post
  end

  def send_invitations(post, invitee)
    setup_email(post.owner)
    @subject    += " #{post.owner.email} has invited you for a conversation."
    recipients invitee.email
    body          :post_url  => DOMAIN + "conversation/show/#{post.unique_id}/#{invitee.unique_id}" ,:post => post
  end

  def comment_notification(post, comment, participant)
    setup_email(comment.owner)  #TODO: we are not using this argument.
    @subject    +=   " #{comment.owner} has added a new comment for #{post.subject}"
    recipients    participant.email
    body          :post_url  => DOMAIN + "conversation/show/#{post.unique_id}/#{participant.unique_id}" ,:post => post, :comment => comment
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
