class PostsController < ApplicationController
  layout :choose_layout, :except => [:plaxo]
  
  before_filter :load_user, :except => [:new, :create,:dashboard,:privacy,:about,:blog,:contact,:plaxo,:help]
  before_filter :check_activated_member,
    :except => [:new,:show, :create, :dashboard, :index, :privacy,:about,:blog,:contact,:plaxo,:help]
  in_place_edit_for :post, :note

  def privacy
  end
  
  def about  
  end

  def contact
  end

  def blog
  end

  def plaxo    
  end
  def help    
  end
  def admin
    if current_user && current_user.admin?
      @posts = Post.find(:all)
      @participants = Engagement.find(:all)
      @comments = Comment.find(:all)
      nonmembers = User.find(:all, :conditions => ["username = ?", "nonmember" ])
      @users = User.find(:all)
      @members = @users.count - nonmembers.count
    else
      redirect_to root_path
    end
  end

  def method_missing(methodname, *args)
       @methodname = methodname
       @args = args
       if methodname == :controller
         controller = 'posts'
       elsif methodname == 'images' || @_params && @_params['path'] && @_params['path'][1] == 'editable.css'
         render :nothing => true 
       else
         render 'posts/404', :status => 404, :layout => false
       end
   end
  def choose_layout
    if [ 'new', 'index','create' ].include? action_name
      'application'
    elsif ['show','ushow','callback'].include? action_name
    'posts'
    elsif ['dashboard','privacy','about','blog','contact', 'admin','help'].include? action_name
      'application'  #the one with shorter width content section
    end
  end

  def check_activated_member
    current_user && current_user.activated?
  end

  def load_user
    if (action_name == 'show'  || action_name == 'send_invites')
      
      if current_user && current_user.activated?
        @user = User.find_by_unique_id(params[:uid]) if params[:uid]
        #Now check if this is the same user as the logged in user
        #If not, then logout the current_user
        force_logout if @user && @user.id != current_user.id
      else
        #load the user based on the unique id
        @user = User.find_by_unique_id(params[:uid]) if params[:uid]
        #if user is member, so force login
        if @user && @user.activated?
          flash[:notice] = "Please login and you will be on your way."
          flash[:email] = @user.email
          store_location if action_name == 'show'  #we do not want to store if it is any other action
          redirect_to login_path
        end
      end
      if @user.nil?
        flash[:error] = "Your identity could not be confirmed from the link that you provided. <br/> Please request the post owner to resend the link."
        force_logout
        redirect_to login_path
      end      
    end
    if (action_name == 'index')
      if current_user && current_user.activated?
        @user = current_user
      else
        flash[:notice] = "Dashboard is a member-only feature. Please signup to enjoy the feature."
        redirect_to root_path
       return
      end
    end
  end

  def dashboard

  end

  def index
    @posts = @user.posts.find(:all, :order => 'updated_at desc')
    if @posts.count < 1
      prompt_message = "Currently you are not engaged in any conversation. Why don't you start one?"
      if flash[:notice].blank?
        flash[:notice] = prompt_message
      else  #when we come here upon login, we will already have a flash[:notice] message
        flash[:notice] += prompt_message
      end
      redirect_to new_post_path
      return
    end

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.xml  
  def show
    @post = params[:pid] ? Post.find_by_unique_id(params[:pid]) : nil
    
    if @post
      if @post.tag_list == ""
        @post.tag_list = "Click here to Add"
      end
      @engagement = Engagement.new
      #update the last_viewed_at
      eng = current_user.engagements.find_by_post_id(@post.id)
      @last_viewed_at = eng.last_viewed_at ? eng.last_viewed_at : Time.parse( "5/14" )
      eng.update_attribute( :last_viewed_at, Time.now )
      #display the count of unread records
      unread = @post.unread_comments_for(current_user, @last_viewed_at)
      #comment_notice = unread > 0 ? pluralize(unread, 'comment') : "No new comments"
      @comment_notice = unread.to_s + " comments since your last visit"
    else
      flash[:error] = "We could not locate this post. Please check the address and try again."
      render 'posts/404', :status => 404, :layout => false and return
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end  
  
  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = session[:post] || Post.new
    @post.subject = params[:title] if params[:title]
    @post.url = params[:url] if params[:url]
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # POST /posts
  # POST /posts.xml
  def create
    session[:post] = nil
    @post =  Post.new(params[:post])     
    
    #create the user object if necessary
    if current_user && current_user.activated?
      @user = current_user
    else
      if  validate_emails(params[:email])
        @user = User.find_by_email(params[:email])
      else
          flash[:notice] = "Your email is turning out to be not valid. Please check and try again"
          redirect_to new_post_path
          return
      end
      if @user && @user.activated?
          #Save this post contents
          session[:post] = @post
          flash[:notice] = "Your email is registered with an account. <br/> Please login first."
          store_location
          redirect_to login_path
          return
      elsif @user.nil?
          #Create a nonmember user record  after checking email veracity
          unless params[:email].blank?
              unless params[:email] =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
                  @post.errors.add(:email, "Your email address does not appear to be valid")
              else
                  @post.errors.add(:email, "Your email domain name appears to be incorrect") unless validate_email_domain(params[:email])
              end
          else
              @post.errors.add(:email, "cannot be empty")
          end
          #If there are no errors looged then go ahead
          if @post.errors.size == 0
            @user = User.create_non_member(params[:email])
          end
      elsif @user.member? && !@user.activated?
          #The user has started the process of signing up but has not activated yet.
          #Save this post contents
          session[:post] = @post
          flash[:notice] = "Your email is registered with an account but not activated yet. <br/> Please activate your account and login first."
          store_location          
          redirect_to login_path
          return
      else
        #The user object is still a nonmember
        #Go ahead with record creation
      end
    end

    @post.unique_id = Post.generate_unique_id
    @post.user_id = @user.id if @user
    if params[:post][:subject] == nil
      @post.errors.add(:subject, "cannot be empty")
    end

    if @post.errors.size == 0
      if @post.description.length == 0
        @post.description = "Add your Initial thoughts"
      end
      if @post.url.length == 0
        @post.url = "Add a link"
      end

      @post.note = "Keep some notes here"
    end
    respond_to do |format|
      if @post.errors.size == 0 && @post.save
        update_tags_for_all_invitees(@post.get_all_participants)
        if current_user && current_user.activated?
          flash[:notice] ='Your email contains the link to this post as well.<br/> '+
            'You can now start inviting your friends for the conversation.'
        else
          flash[:notice] = 'Your Conversation page was successfully created. <br/>'
          flash[:notice] +='Please check your email for the link to this post you just created. <br/>' +
            'This redirect helps us to confirm your ownership of the provided email.'+
                       'Happy Engaging!'
          redirect_to root_url
          return
        end
        format.html { redirect_to(@post.get_url_for(@user,'show')) }
        #format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        format.html { render :action => 'new'  } #redirect_to new_post_path
        #format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /posts/1
  # DELETE /posts/1.xml
  def destroy
    @post = Post.find(params[:id])
    @post.destroy

    respond_to do |format|
      format.html { redirect_to(posts_url) }
      format.xml  { head :ok }
    end
  end

  def set_post_description
    @post = Post.find(params[:id])
    if params[:value] && params[:value].length > 0
      @post.description = params[:value]
    else
       @post.description = "Add your Initial thoughts"
    end
    if @post.save
        render :text => @post.description
    end
  end

  def set_post_subject
    @post = Post.find(params[:id])
    prior_subject = @post.subject
    if params[:value] && params[:value].length > 0
      @post.subject = params[:value]
      if @post.save
        render :text => @post.subject
      else
        render :text => prior_subject
      end
    else
      render :text => prior_subject
    end
  end


  def set_post_url
    @post = Post.find(params[:id])
    if params[:value] && params[:value].length > 0
      @post.url = params[:value]
    else
       @post.url = "Add a link"
    end
    if @post.save        
        render :update do |page|
          page.replace_html 'url-text', :partial => 'update_url_text', :object => @post
          page.replace_html 'url-link', :partial => 'update_url_link', :object => @post
        end       
    end
  end

  def set_post_note
    @post = Post.find(params[:id])
    #@post.note = params[:value]
    if @post.update_attributes(:note => params[:value])
      render :text => @post.note
    else
      render :text => "There was a problem saving your note. Please refresh and try again."
    end
  end

 def set_post_tag_list
    @post = Post.find(params[:id])    
    #@post.user_id = nil #  We don't know the user here  WARNING: NEVER set this as this overrides the post.user_id
    @post.tag_list = params[:value]
    @post.save
    update_tags_for_all_invitees(@post.get_all_participants)
    if params[:value] && params[:value].length > 0      
      render :text => @post.tag_list
    else
      render :text => "Click here to Add"
    end
  end
  def get_reco_contacts    
    @users  = []
    unless (params[:pid].nil? || params[:uid].nil?)
        @post = Post.find(params[:pid])
        @user = User.find_by_unique_id(params[:uid])
        keyword = @post.tag_list
        unless keyword.blank?
              @users  = User.find_tagged_with(keyword, :contacts => @user.get_all_contacts)
        end
    end
    render :update do |page|
        a = []
        @users.each{|u| a << u.get_contact_id }
        page.replace_html 'reco-contacts', "#{a.join(", ")}"
    end
  end
  private  
  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
  end
  # PUT /posts/1
  # PUT /posts/1.xml
  def update
    @post = Post.find(params[:id])

    respond_to do |format|
      if @post.update_attributes(params[:post])
        flash[:notice] = 'Post was successfully updated.'
        format.html { redirect_to(@post) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
  end

end
