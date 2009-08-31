class PostsController < ApplicationController
  layout :choose_layout
  
  before_filter :load_user, :except => [:new, :create,:dashboard]
  before_filter :check_activated_member, :except => [:new, :show, :create, :dashboard, :index]

  def choose_layout
    if [ 'new', 'index' ].include? action_name
      'application'
    elsif ['show','shown'].include? action_name
    'posts'
    elsif ['dashboard'].include? action_name
      'application'  #the one with search tabs
    end
  end

  def check_activated_member
    current_user && current_user.activated?
  end

  def load_user
    if (action_name == 'show')
      if current_user && current_user.activated?
        @user = current_user
      else
        #load the user based on the unique id
        @user = User.find_by_unique_id(params[:uid]) if params[:uid]
      end
      if @user.nil?
        flash[:notice] = "Your identity could not be confirmed from the link that you provided. <br/> Please request the post owner to resend the link."
        redirect_to login_path
      end
      return
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
      @post.validated_at = Time.now.utc
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
          flash[:notice] = "Your email is registered with an account. <br/> Please login."
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
          eng = Engagement.new
          eng.invited_by = @post.owner  #TODO Shoudl this be 0 ?
          eng.invited_when = Time.now.utc
          eng.post = @post
          eng.invitee = @post.owner
          eng.save

        flash[:notice] = 'Post was successfully created. <br/>'
        
        if current_user && current_user.activated?
          flash[:notice] +='Your email contains the link to this post as well.<br/> '+
            'You can now start inviting your friends for the conversation.'
        else
          flash[:notice] +='Please check your email for the link to this post you just created. <br/>' +
            'This redirect helps us to confirm your ownership of the provided email.'+
                       'Happy Conversing!'
          redirect_to root_url
          return
        end
        format.html { redirect_to(@post) }
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
    @post.description = params[:value]
    if @post.save
      render :text => @post.description
    else
      render :text => "There was a problem saving your description. Please refresh and try again."
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
