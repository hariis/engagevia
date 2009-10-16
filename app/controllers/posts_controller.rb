class PostsController < ApplicationController
  layout :choose_layout
  
  before_filter :load_user, :except => [:new, :create,:dashboard,:privacy,:about]
  before_filter :check_activated_member, :except => [:new, :show,:send_invites, :create, :dashboard, :index, :privacy,:about]
  def privacy
   
  end
  def about
    
  end
  def method_missing(methodname, *args)
       @methodname = methodname
       @args = args
       if methodname == :controller
         controller = 'posts'
       else
         render 'posts/404', :status => 404, :layout => false
       end
   end
  def choose_layout
    if [ 'new', 'index' ].include? action_name
      'application'
    elsif ['show'].include? action_name
    'posts'
    elsif ['dashboard','privacy','about'].include? action_name
      'application'  #the one with shorter width content section
    end
  end

  def check_activated_member
    current_user && current_user.activated?
  end

  def load_user
    if (action_name == 'show' || action_name == 'send_invites')
      if current_user && current_user.activated?
        @user = current_user
      else
        #load the user based on the unique id
        @user = User.find_by_unique_id(params[:uid]) if params[:uid]
        #Still require the user to login so we can maintain a session
        if @user.activated?
          flash[:notice] = "Please login and you will be on your way"
          flash[:email] = @user.email
          store_location if action_name == 'show'  #we do not want to store if it is any other action
          redirect_to login_path
        end
      end
      if @user.nil?
        flash[:error] = "Your identity could not be confirmed from the link that you provided. <br/> Please request the post owner to resend the link."
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
    if params[:pid]
      @post = Post.find_by_unique_id(params[:pid])
      @engagement = Engagement.new
    else
      render 'posts/404', :status => 404, :layout => false and return
    end
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end  
  def send_invites
    if params[:pid]
      @post = Post.find_by_unique_id(params[:pid])
      @engagement = Engagement.new
    else
      render 'posts/404', :status => 404, :layout => false and return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
      format.js { render_to_facebox }
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
    if @post.description.length == 0
      @post.description = "Add your Initial thoughts"
    end
    if @post.url.length == 0
      @post.url = "Add a link"
    end

    
    @post.note = "Keep some notes here"
    
    
    #create the user object if necessary
    if current_user && current_user.activated?
      @user = current_user
    else
      if  validate_emails(params[:from_email])
        @user = User.find_by_email(params[:from_email])
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
          #Create a nonmember user record
          @user = User.create_non_member(params[:from_email])
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
    @post.user_id = @user.id
    
    respond_to do |format|

      if @post.save
        #&& @user.posts << @post
         #save an engagement
#          eng = Engagement.new
#          eng.invited_by = @post.owner  #TODO Shoudl this be 0 ?
#          eng.invited_when = Time.now.utc
#          eng.post = @post
#          eng.invitee = @post.owner
#          eng.save      
        
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
        format.html { redirect_to new_post_path }
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
        render :text => @post.url
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
    prior_tags = @post.tag_list
    if params[:value] && params[:value].length > 0
      @post.tag_list = params[:value]
      if @post.save
        render :text => @post.tag_list
      else
        render :text => prior_tags
      end
    else
      render :text => prior_tags
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
