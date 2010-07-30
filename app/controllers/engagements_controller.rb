class EngagementsController < ApplicationController
  # include the oauth_system mixin
  include OauthSystem
  
  before_filter :load_post, :except => [:set_notification, :callback, :exclude]
  before_filter :load_user, :only => [:create, :get_auth_from_twitter, :send_invites]
  layout 'posts'
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

  def set_all_notifications
    @post = Post.find(params[:post_id])
    engagements = Engagement.find(:all, :conditions => ['post_id = ?',  @post.id] )
    engagements.each do |eng|
        if params[:set] == 'true'
          eng.notify_me = true
       else
          eng.notify_me = false
       end
       eng.save
    end
    render :update do |page|
        page.replace_html "all-notifications", :partial => "all_notifications"
    end
  end
  def create
    #Save the engagements
    if params[:invite_type] == 'email'
      if params[:email_invitees]
        send_email_invites(params[:email_invitees])
      else
        send_ev_invites
      end
    else
      send_twitter_invites(params[:followers])
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
        
  def exclude
      engagement = Engagement.find(params[:id]) if params[:id]
      engagement.destroy
      
      render :update do |page|
          page.select("#participant_details_#{engagement.invitee.id}").each { |b| b.visual_effect :fade, :startcolor => "#ff0000",
												:endcolor => "#cf6d0f", :duration => 5.0 }
          #page.replace_html "participant_details_#{engagement.invitee.id}", ""
      end
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

def get_auth_from_twitter
  login_by_oauth  #in lib/oauth_system
end

 def method_missing(methodname, *args)
#       @methodname = methodname
#       @args = args
#        render 'posts/404', :status => 404, :layout => false
   end

   def send_invites          
      @engagement = Engagement.new
      #data for invite from ev tab      
      @ic, @ec = @user.get_inner_and_extended_contacts      
      keywords = @post.tag_list
      @reco_users  = []
      @reco_users_ids = []
      unless keywords.blank?
            @reco_users  = User.get_recommended_contacts(keywords, @user.get_ids_for_all_contacts)
            @reco_users.each{|u| @reco_users_ids << u.id }
      end

      #data for twitter tab
      if @user.token.blank?
        @followers = nil  #redirect to twitter for authorization
        login_by_oauth #sets the @authorization_url
      else
        @followers = []
        @followers = get_followers(@user.token,@user.secret,@user.screen_name)
      end    

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
      format.js { render_to_facebox }
    end
  end

 private
 def send_email_invites(email_ids)      
   create_engagements_and_send(email_ids)
   
    render :update do |page|
      if @status_message.blank?
        #page.hide 'facebox'
        page.insert_html :bottom, 'participants-list', :partial => 'participants', :locals => { :participants => @email_participants }
        page.replace_html 'invite-status', "#{@email_participants ? pluralize(@email_participants.size ,"participant") : "None"} added."
        page.replace_html "send-status", "#{@email_participants ? pluralize(@email_participants.size ,"invitation") : "None"} sent."
        page.select("#send-status").each { |b| b.visual_effect :fade, :startcolor => "#4B9CE0",
												:endcolor => "#cf6d0f", :duration => 15.0 }
        page.select(".new-p").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 5.0 }
        page.select("#invite-status").each { |b| b.visual_effect :fade, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 15.0 }
        page.replace_html "participant-count", "(#{@post.engagements.size})"
      else
        page.replace_html "send-status", @status_message
      end
    end
 end
 
 def create_engagements_and_send(invitees_emails)
   @email_participants = {}
   @status_message = ""
   if invitees_emails.length > 0
       if validate_emails(invitees_emails)  #returns @parsed_entries
            #Limit sending only to first 10

            #Get userid of invitees - involves creating dummy accounts
            requested_participants = []
            requested_participants = Post.get_invitees(@parsed_entries)

            #Add them to engagement table
            requested_participants.each do |invitee|
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
                    @email_participants[invitee] = eng
                end
              end
            end
             #update the participants' tags with post tags - Now done only on first comment
             #update_tags_for_all_invitees(@email_participants.keys)
             
             #create membership and add requested_participants to the inner contact.
             #create_membership_and_add_to_contacts(@email_participants.keys)
             #now send emails
            @post.send_invitations(@email_participants,@user) if @email_participants.size > 0
            #Delayed::Job.enqueue(MailingJob.new(@post, invitees))            
        else
                @status_message = "<div id='failure'>There was some problem sending the invitation(s). <br/>" + @invalid_emails_message + "</div>"
        end
    else
        @status_message = "<div id='failure'>Please enter valid email addresses and try again.</div>"
    end
 end
 def send_ev_invites
   #separate the email ids from twitter ids
   contacts = params[:ev_contacts].split(',') unless params[:ev_contacts].nil?
   email_ids = []
   twitter_ids = []
   unless contacts.blank?
     contacts.each do |c|
       #get contact_ids from the users
       contact_id = User.find_by_unique_id(c).get_contact_id
       #separate emails from twitter ids
       contact_id.include?('@') ? email_ids << contact_id : twitter_ids << contact_id
     end
   end
   #call send_email_invites
   unless email_ids.blank?     
      create_engagements_and_send(email_ids.join(','))
   end
   #call send_twitter_invites
   unless twitter_ids.blank?
      create_engagements_and_dm(twitter_ids)
   end

    render :update do |page|
      if @status_message.blank? && @error_message.blank?
        #page.hide 'facebox'
        page.insert_html :bottom, 'participants-list', :partial => 'participants', :locals => { :participants => @email_participants } unless @email_participants.blank?
        page.insert_html :bottom, 'participants-list', :partial => 'participants', :locals => { :participants => @twitter_participants } unless @twitter_participants.blank?

        total_count = 0
        total_count = @email_participants.size unless @email_participants.blank?
        total_count += @twitter_participants.size unless @twitter_participants.blank?

        page.replace_html 'invite-status', "#{total_count > 0 ? pluralize(total_count ,"participant") : "None"} added."
        page.replace_html "send-status", "#{total_count > 0 ? pluralize(total_count ,"invitation") : "None"} sent."


        page.select("#send-status").each { |b| b.visual_effect :fade, :startcolor => "#4B9CE0",
												:endcolor => "#cf6d0f", :duration => 15.0 }
        page.select(".new-p").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 5.0 }
        page.select("#invite-status").each { |b| b.visual_effect :fade, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 15.0 }
        page.replace_html "participant-count", "(#{@post.engagements.size})"
      else
        page.replace_html "send-status", @status_message + "<br/>" + @error_message
      end
    end
 end
 def send_twitter_invites(twitter_followers)    
    create_engagements_and_dm(twitter_followers)
   
    render :update do |page|
       if @error_message.blank?
        #page.hide 'facebox'        
        page.insert_html :bottom, 'participants-list', :partial => 'participants', :locals => { :participants => @twitter_participants }
        page.replace_html 'invite-status', "#{@twitter_participants ? pluralize(@twitter_participants.size ,"participant") : "None"} added."
        page.replace_html "send-status", "#{@twitter_participants ? pluralize(@twitter_participants.size ,"invitation") : "None"} sent."
        page.select("#send-status").each { |b| b.visual_effect :fade, :startcolor => "#4B9CE0",
												:endcolor => "#cf6d0f", :duration => 15.0 }
        page.select(".new-p").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
												:endcolor => "#cf6d0f", :duration => 5.0 }
        page.select("#invite-status").each { |b| b.visual_effect :fade, :startcolor => "#fb3f37",
          :endcolor => "#cf6d0f", :duration => 15.0 }
        page.replace_html "participant-count", "(#{@post.engagements.size})"
       else
         page.replace_html "send-status", @error_message
       end
    end
 end
 def create_engagements_and_dm(twitter_followers)
   @twitter_participants = {}
   unless twitter_followers.nil?
       #Get userid of invitees - involves creating dummy accounts
        requested_participants = []

        requested_participants = Post.get_twitter_invitees(twitter_followers)
        #Add them to engagement table
        requested_participants.each do |invitee|
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
              @twitter_participants[invitee] = eng
          end
        end
        #update the participants' tags with post tags
        #update_tags_for_all_invitees(@twitter_participants.keys)
     @error_message = ""
     begin
        send_twitter_notification(@twitter_participants) if @twitter_participants.size > 0
     rescue
        @error_message = "<div id='failure'>There was some problem sending the invitation(s) via Twitter.<br/> Please try again a little later.</div>"
     end

    end
 end
 def send_twitter_notification(followers)
   followers.each_key do |follower|
      message = DOMAIN + "conversation/show/#{@post.unique_id}/#{follower.unique_id}"      
      send_direct_message! follower.screen_name, "Please join me for a conversation at " + message + " about #{truncate(@post.subject,20,"...")}"
   end
  end
end
