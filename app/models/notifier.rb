class Notifier < ActionMailer::Base

include ActionView::Helpers::TextHelper
layout 'notifications'
default_url_options[:host] = "www.engagevia.com"

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
    
    body          :activation_url  => DOMAIN + "activate/#{user.perishable_token}"
  end

  def confirm_activation(user)
    setup_email(user)
    subject    += 'Woohoo! Your account has been activated!'
    body       :url  => DOMAIN
  end

  def post_link(post)
    setup_email(post.owner)
    @subject    += ' [New Conversation]' + truncate(post.subject, :omission => "...", :length => 30)
    recipients    post.owner.email
    
    body          :post_url  => DOMAIN + "posts/show?pid=#{post.unique_id}&uid=#{post.owner.unique_id}" , :post => post
  end

  def send_invitations(post, invitee, inviter, share)
    setup_email(post.owner)
    if share
      @subject    += " #{inviter.display_name} is having a conversation on #{truncate(post.subject,20,"...")}"
      #post_url = DOMAIN + "posts/show?pid=#{post.unique_id}&iid=#{inviter.unique_id}&uid=#{invitee.unique_id}"
      post_url = DOMAIN + "posts/show?pid=#{post.unique_id}&iid=#{inviter.unique_id}"
    else
      @subject    += " #{inviter.display_name} has invited you for a conversation on #{truncate(post.subject,20,"...")}"
      post_url = DOMAIN + "posts/show?pid=#{post.unique_id}&uid=#{invitee.unique_id}"
    end
    recipients invitee.email
    body          :post_url  => post_url ,:post => post, :inviter => inviter, :invitee => invitee, :share => share
  end

  def comment_notification(post, comment, participant)
    setup_email(comment.owner)  #TODO: we are not using this argument.
    @subject    +=   " #{comment.owner.display_name} has added a new comment on #{truncate(post.subject,20,"...")}"
    recipients    participant.email
    body          :post_url  => DOMAIN + "posts/show?pid=#{post.unique_id}&uid=#{participant.unique_id}" ,:post => post, :comment => comment
  end
  
  def send_experience(experience)
    setup_email()  #TODO: we are not using this argument.
    @subject    +=   "User Feedback"
    recipients    "engagevia@gmail.com"
    body          :experience => experience
  end
  
  protected
    def setup_email(user=nil)      
      @from        = "EngageVia <EngageVia-notifier@engagevia.com>"
      headers         "Reply-to" => "engagevia@gmail.com"
      @subject     = ""
      @sent_on     = Time.zone.now
      @content_type = "text/html"
    end
  end
