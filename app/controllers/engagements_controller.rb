class EngagementsController < ApplicationController
  before_filter :load_post, :except => [:set_notification]
  before_filter :load_user, :only => [:create, :get_followers]

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

 def get_followers
    # Renders "hello david"
     #render :inline => "<%= 'hello ' + name %>", :locals => { :name => "david" }
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

 def method_missing(methodname, *args)
       @methodname = methodname
       @args = args
        render 'posts/404', :status => 404, :layout => false
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
       else
         #page.replace_html "send-status", @error_message
       end
    end
 end
end
