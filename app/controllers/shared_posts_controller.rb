class SharedPostsController < ApplicationController

  before_filter :load_post, :except => [:fb_authorize,:fb_callback]
  before_filter :load_user, :only => [:create, :send_invites, :share_open_invites]
  layout 'posts', :except => [:fb_callback]
  layout 'logo_footer' , :only => [:fb_callback]
  
  #-----------------------------------------------------------------------------------------------------
  def load_user
    @user = User.find_by_unique_id(params[:uid]) if params[:uid]
  end
  
  #-----------------------------------------------------------------------------------------------------
  def load_post
    @post = Post.find(params[:post_id])
  end

  #-----------------------------------------------------------------------------------------------------
  def share_open_invites
   @engagement = Engagement.new
    #data for invite from ev tab
    #@ic, @ec = @user.get_inner_and_extended_contacts
    keywords = @post.tag_list
    @reco_users  = []
    @reco_users_ids = []
    unless keywords.blank?
          @reco_users  = User.get_recommended_contacts(keywords, @user.get_ids_for_all_contacts)
          @reco_users.each{|u| @reco_users_ids << u.id }
    end
    #data for fb tab
   @authorization_url = @post.get_fb_auth_url
   session[:post_id] = params[:post_id] if params[:post_id]
   session[:uid] = params[:uid] if params[:uid]
   respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
      format.js { render_to_facebox }
    end
 end

 #-----------------------------------------------------------------------------------------------------
 #Facebook
 def fb_authorize
    redirect_to OAuthClient.web_server.authorize_url(
      :redirect_uri => auth_callback_url,
      :scope => 'email,offline_access,publish_stream'
    )
 end

 #-----------------------------------------------------------------------------------------------------
 def fb_callback
    begin
      access_token = OAuthClient.web_server.access_token(
        params[:code], :redirect_uri => auth_callback_url
      )
      @post = Post.find(session[:post_id]) if session[:post_id]
      @user = User.find_by_unique_id(session[:uid]) if session[:uid]
      @fb_user = FacebookUser.create_from_fb(access_token, @user)

      #make up the generic url
      @fb_url = @post.get_readonly_url(@user)
      #make up the message
      wall_message = "I am engaged in a conversation about '#{@post.subject}' at EngageVia." +
        "If you are interested, you can join me. The link to the conversation is here " +
        "#{@fb_url}"
      @fb_user.post(wall_message)
      flash[:notice] = "The open invitation has been successfully posted to your Facebook Profile. <br/><br/>
                        Please close this window and proceed with your conversation."
    rescue => err
      RAILS_DEFAULT_LOGGER.error "Failed to get callback from Facebook" + err
      flash[:notice] = "There was a problem posting the open invitation to your Profile. <br/><br/>
                        Please close this window and try again later."
    end
 end

 #-----------------------------------------------------------------------------------------------------
 def create
      if params[:email_invitees]
        send_email_invites(params[:email_invitees])
      else
        send_ev_invites
      end
 end
  
 #-----------------------------------------------------------------------------------------------------
 private
 #-----------------------------------------------------------------------------------------------------
 def send_email_invites(email_ids)
      create_shared_post_and_send(email_ids)
      render :update do |page|
        if @status_message.blank?        
          page.replace_html "send-status", "Shared with #{@email_participants ? pluralize(@email_participants.size ,"friend") : "None"}."
          page.select("#send-status").each { |b| b.visual_effect :fade, :startcolor => "#4B9CE0",
                                                                                                  :endcolor => "#cf6d0f", :duration => 15.0 }          
        else
          page.replace_html "send-status", @status_message
        end
      end
 end

 #-----------------------------------------------------------------------------------------------------
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
      create_shared_post_and_send(email_ids.join(','))
   end
   #call send_twitter_invites
   unless twitter_ids.blank?
      #create_shared_post_and_dm(twitter_ids)
   end

    render :update do |page|
      if @status_message.blank? && @error_message.blank?
       
        total_count = 0
        total_count = @email_participants.size unless @email_participants.blank?
        total_count += @twitter_participants.size unless @twitter_participants.blank?
        
        page.replace_html "send-status", "Shared with #{total_count > 0 ? pluralize(total_count ,"friend") : "None"}."
        page.select("#send-status").each { |b| b.visual_effect :fade, :startcolor => "#4B9CE0",
												:endcolor => "#cf6d0f", :duration => 15.0 }       
      else
        page.replace_html "send-status", @status_message + "<br/>" + @error_message
      end
    end
 end
 
 #-----------------------------------------------------------------------------------------------------
 def create_shared_post_and_send(invitees_emails)
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
                  sp_exists = SharedPost.find(:first, :conditions => ['user_id = ? and post_id = ?', invitee.id, @post.id])
                  if sp_exists.nil?
                      sp = SharedPost.new
                      sp.shared_by = @user.id
                      sp.shared_when = Time.now.utc
                      sp.post = @post
                      sp.invitee = invitee
                      sp.shared_via = 'email'
                      sp.save
                      @user.add_mutually_to_address_book(invitee) if @user.id != invitee.id
                      @email_participants[invitee] = sp
                  end
                end
              end

              #now send emails or daily digest once a day
              @post.send_invitations(@email_participants, @user, true) if @email_participants.size > 0
              #Delayed::Job.enqueue(MailingJob.new(@post, invitees))
          else
              @status_message = "<div id='failure'>There was some problem sharing the invitation(s). <br/>" + @invalid_emails_message + "</div>"
          end
      else
          @status_message = "<div id='failure'>Please enter valid email addresses and try again.</div>"
      end
 end
 #-----------------------------------------------------------------------------------------------------
end
