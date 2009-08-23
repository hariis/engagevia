class PostsController < ApplicationController
  # GET /posts
  # GET /posts.xml
  before_filter :load_user, :except => [:new, :create]
  before_filter :check_activated_member, :except => [:new, :show, :create]

  def check_activated_member
    current_user.activated?
  end
  def load_user
    if (controller[:action_name] == :show)
      if current_user.activated?
        @user = current_user
      else
        #load the user based on the email id
        uid = params[:uid]
        @user = User.find_by_email(params[:email]) if uid
      end
    end
    if (controller[:action_name] == :index)
      if current_user.activated?
        @user = current_user
      else
       redirect_to login_path
      end
    end
  end
  def index
    @posts = @user.posts.find(:all)

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @posts }
    end
  end

  # GET /posts/1
  # GET /posts/1.xml
  def show
    if current_user.activated?
       @post = Post.find(params[:id])
    else
       #load the post based on unique id
      @post = Post.find_by_unique_id(params[:uid]) if params[:uid]
    end   
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # GET /posts/new
  # GET /posts/new.xml
  def new
    @post = Post.new
    
    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @post }
    end
  end

  # POST /posts
  # POST /posts.xml
  def create

    @post = Post.new(params[:post])
    @post.unique_id = Post.get_unique_id
    
    respond_to do |format|
      if @user.posts << @post #@post.save
        flash[:notice] = 'Post was successfully created. <br/> Your email contains the link to this conversation as well'
        format.html { redirect_to(@post) }
        #format.xml  { render :xml => @post, :status => :created, :location => @post }
      else
        format.html { render :action => "new" }
        #format.xml  { render :xml => @post.errors, :status => :unprocessable_entity }
      end
    end
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

  private
  # GET /posts/1/edit
  def edit
    @post = Post.find(params[:id])
  end
end
