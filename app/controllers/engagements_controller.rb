class EngagementsController < ApplicationController
  # include the oauth_system mixin
  include OauthSystem
  
  before_filter :load_post, :except => [:set_notification, :get_auth_from_twitter, :callback]
  before_filter :load_user, :only => [:create, :get_followers,:get_auth_from_twitter]

  def load_user
    @user = User.find_by_unique_id(params[:uid]) if params[:uid]
  end
  def load_post
    @post = Post.find(params[:post_id])
  end

  def set_notification
     @engagement = Engagement.find(params[:id])
     if params[:set] == 'true'
        @engagement.notify_me = true
     else
       @engagement.notify_me = false
     end
     @engagement.save
  end

  def create
    #Save the engagements
    if params[:invite_type] == 'email'
      send_email_invites
    else
      send_twitter_invites
    end
  end

  def destroy
  end
  def resend_invite
    eng_exists = Engagement.find(params[:id]) if params[:id]
    if eng_exists
      @participants = {}
      @participants[eng_exists.invitee] = eng_exists
      @post.send_invitations(@participants,@post.owner) if @participants.size > 0
      @status = "Invite sent"
    else
      @status = "Error sending! Try again"
    end
    render :update do |page|
        page.replace_html "resend_#{eng_exists.invitee.id}", @status
    end
  end
 def get_followers   
     from_config = {}
     from_config[:twitid] = params[:twitid]
     from_config[:password] = params[:twitp]

     @error_message = ""
     begin
        @followers = Engagement.get_followers(from_config)
        if @followers.size == 0
          @error_message = "There was a problem connecting to Twitter.<br/> Please try again a little later."
        elsif @followers.blank?
          @error_message = "No followers found."
        end
     rescue Exception => e
       if e.type.inspect == "Twitter::Unauthorized"
        @error_message = "Could not login to Twitter.<br/> Please check your credentials <br/>and try again a little later. "
       else
        @error_message = "There was a problem talking to Twitter.<br/> Please try again a little later."
       end
     end
     respond_to do |format|
        format.js {            
              render_to_facebox  :partial => 'followers.html.erb', :object => @followers
            #page.show "twit-invite-btn"
        }
      end
  end
def get_auth_from_twitter
#  @request_token = User.consumer.get_request_token
#
#  session[:request_token] = @request_token.token
#  session[:request_token_secret] = @request_token.secret
#  session[:post_id] = params[:post_id] if params[:post_id]
#  session[:uid] = params[:uid] if params[:uid]
#  # Send to twitter.com to authorize
#  redirect_to @request_token.authorize_url
   login_by_oauth
end
def callback2
    @user = User.find_by_unique_id(session[:uid]) if session[:uid]
    @post = Post.find(session[:post_id]) if session[:post_id]

    if (@user.nil? || @post.nil?)
        @error_message = "We are having problems locating your post. Please try inviting again."
    elsif (@user.token != "" && @user.secret != "")
       getfollowers
    else
      @request_token = OAuth::RequestToken.new(User.consumer,
      session[:request_token],
      session[:request_token_secret])
      # Exchange the request token for an access token.
      @access_token = @request_token.get_access_token
      @twitter_response = User.consumer.request(:get, '/account/verify_credentials.json', @access_token, { :scheme => :query_string })
      case @twitter_response
        when Net::HTTPSuccess
          user_info = JSON.parse(@twitter_response.body)
          unless user_info['screen_name']
            @error_message = "Authentication failed"
          end

          # We have an authorized user, save the information to the database.
          @user.update_attributes(:screen_name => user_info['screen_name'],:token => @access_token.token,:secret => @access_token.secret )
          # Redirect to the show page
          getfollowers
        else
            @error_message = "Authentication failed"
      end
    end
     respond_to do |format|
        format.html {
              @engagement = Engagement.new
              format.html {  render :controller => 'posts', :action => 'show' }
        }
    end
 end

def getfollowers 
    @access_token = OAuth::AccessToken.new(User.consumer, @user.token, @user.secret)

    @twitter_response = User.consumer.request(:get, '/statuses/followers.json', @access_token,
    { :scheme => :query_string })
    case @twitter_response
    when Net::HTTPSuccess
        @followers = JSON.parse(@twitter_response.body)        
    else
      # The user might have rejected this application. Or there was some other error during the request.
      @error_message =  "There was a problem getting followers from Twitter.<br/> Please try again a little later."      
    end   
end

 def method_missing(methodname, *args)
#       @methodname = methodname
#       @args = args
#        render 'posts/404', :status => 404, :layout => false
   end
 private
 def send_email_invites
   #Send email invites
    invitees_emails = params[:email_invitees]

    if invitees_emails.length > 0
          if validate_emails(invitees_emails)
                  valid_emails =[]
                  valid_emails = string_to_array(invitees_emails)

                  #Limit sending only to first 10

                  #Get userid of invitees - involves creating dummy accounts
                  @requested_participants = []
                  @participants = {}
                  @requested_participants = Post.get_invitees(valid_emails)
                  #Add them to engagement table
                  @requested_participants.each do |invitee|
                    if !invitee.nil?
                      eng_exists = Engagement.find(:first, :conditions => ['user_id = ? and post_id = ?',invitee.id, @post.id])
                      if eng_exists.nil?
                          eng = Engagement.new
                          eng.invited_by = @user.id
                          eng.invited_when = Time.now.utc
                          eng.post = @post
                          eng.invitee = invitee
                          eng.invited_via = 'email'
                          eng.save
                          @participants[invitee] = eng
                      end
                    end
                  end

                   #now send emails
                  @post.send_invitations(@participants,@user) if @participants.size > 0
                  #Delayed::Job.enqueue(MailingJob.new(@post, invitees))

                  @status_message = "<div id='success'>Invitations sent</div>"
          else
                  @status_message = "<div id='failure'>There was some problem sending. <br/>" + @invalid_emails_message + "</div>"

          end

    else
              @status_message = "<div id='failure'>Please enter valid email addresses and try again.</div>"
    end

   
    render :update do |page|
        page.hide 'facebox'
        page.insert_html :bottom, 'participants-list', :partial => 'participants'
        page.replace_html 'invite-status', "#{@participants? pluralize(@participants.size ,"participant") : "None"} added."
        #page.replace_html "send-status", @status_message
        #page.select("send-status").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
				#								:endcolor => "#cf6d0f", :duration => 5.0 }
        page.select(".new-p").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 5.0 }
        page.select("#invite-status").each { |b| b.visual_effect :fade, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 5.0 }
        page.replace_html "participant-count", "(#{@post.engagements.size})"
    end
 end

 def send_twitter_invites
    #Send twitter notifications
    #Get the twitter ids of the invitees
    @followers = params[:followers]
    @from_config = {}
    @from_config[:twitid] = params[:twitter_id]
    @from_config[:password] = params[:twitter_passwd]
    if !params[:followers].nil?  &&  !params[:twitter_id].nil? && !params[:twitter_passwd].nil?
       #Get userid of invitees - involves creating dummy accounts
        @requested_participants = []
        @participants = {}
        @requested_participants = Post.get_twitter_invitees(@followers)
        #Add them to engagement table
        @requested_participants.each do |invitee|
          #check if each user has already been invited
          eng_exists = Engagement.find(:first, :conditions => ['user_id = ? and post_id = ?',invitee.id, @post.id])
          if eng_exists.nil?
              eng = Engagement.new
              eng.invited_by = @user.id
              eng.invited_when = Time.now.utc
              eng.post = @post
              eng.invitee = invitee
              eng.invited_via = 'twitter'
              eng.save
              @participants[invitee] = eng
          end
        end
     @error_message = ""
     begin
        @post.send_twitter_notification(@from_config, @participants) if @participants.size > 0
     rescue
        @error_message = "Unable to send invites.<br/> Please check your credentials <br/>and try again a little later."
     end
             
    end
   
    render :update do |page|
       if @error_message.blank?
        page.hide 'facebox'
        page.insert_html :bottom, 'participants-list', :partial => 'participants'
        page.replace_html 'invite-status', "#{@participants? pluralize(@participants.size ,"participant") : "None"} added."
        #page.replace_html "send-status", @status_message
        #page.select("send-status").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
				#								:endcolor => "#cf6d0f", :duration => 5.0 }
        page.select(".new-p").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 5.0 }
        page.select("#invite-status").each { |b| b.visual_effect :fade, :startcolor => "#fb3f37",
          :endcolor => "#cf6d0f", :duration => 50.0 }
        page.replace_html "participant-count", "(#{@post.engagements.size})"
       else
         #page.replace_html "send-status", @error_message
       end
    end
 end
end
