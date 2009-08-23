class EngagementsController < ApplicationController
  before_filter :load_post

  def load_post
    @post = Post.find(params[:post_id])
  end
  def create
    #Send email invites
    invitees_emails = params[:email_invitees]

    if invitees_emails.length > 0
          if validate_emails(invitees_emails)
                  #Limit sending only to first 10
                  invitees_emails.slice!(0...9) if invitees_emails.length > 10
                  #Get userid of invitees - involves creating dummy accounts
                  @participants = Post.get_invitees(invitees_emails)
                  #Add them to engagement table
                  @participants.each {|invitee| @post.users << invitee }
                  #now send emails
                  @post.send_invitations(invitees_emails)
                  #Delayed::Job.enqueue(MailingJob.new(@post, invitees))

                  @status_message = "<div id='success'>Invitations sent</div>"
                  
          else
                  @status_message = "<div id='failure'>There was some problem sending. <br/>" + @invalid_emails_message + "</div>"

          end
          #Update right column with list of invitees
    else
              @status_message = "<div id='failure'>One or more of the email addresses is invalid. <br/> Please check and try again.</div>"
    end

    #Send twitter notifications
    #Get the twitter ids of the invitees
    @followers = params[:followers]
    @from_config = {}
    @from_config[:twitid] = params[:twitter_id]
    @from_config[:password] = params[:twitter_passwd]
    Engagement.send_twitter_notification(@from_config, @followers)

    render :update do |page|
        page.insert_html :bottom, 'participants', :partial => 'participants'
        page.replace_html "send-status", @status_message
        page.select(".new-p}").each { |b| b.visual_effect :highlight, :startcolor => "#e9ef3d",
												:endcolor => "#ffffff", :duration => 5.0 }
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
     @followers = Engagement.get_followers(from_config)


    render :update do |page|
        page.replace_html "twitter_followers", :partial => 'followers'
    end

  end
end
