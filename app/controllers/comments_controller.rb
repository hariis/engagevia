class CommentsController < ApplicationController
  # GET /comments
  # GET /comments.xml
  
  before_filter :load_post
  before_filter :check_current_user, :only => [:create]

  def load_post
    @post = Post.find(params[:post_id])
  end

  def check_current_user
    current_user
  end

  def index
    @comments = @post.comments

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @comments }
    end
  end

  # GET /comments/1
  # GET /comments/1.xml
  def show
    @comment = @post.comments.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/new
  # GET /comments/new.xml
  def new
    @comment = @post.comments.build

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @comment }
    end
  end

  # GET /comments/1/edit
  def edit
    @comment = @post.comments.find(params[:id])
  end

  # POST /comments
  # POST /comments.xml
  def create
    @comment = @post.comments.build(params[:comment])
    @comment.user_id = current_user.id
    @comment.parent_id = 0
    respond_to do |format|

      if @post.comments << @comment
        flash[:notice] = 'Comment was successfully created.'
        format.html { redirect_to(@post) }
        format.xml  { render :xml => @comment, :status => :created, :location => @comment }
      else
        format.html { redirect_to(@post) }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = @post.comments.find(params[:id])

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        flash[:notice] = 'Comment was successfully updated.'
        format.html { redirect_to(@post, @comment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = @post.comments.find(params[:id])
    @comment.destroy

    respond_to do |format|
      format.html { redirect_to(@post, @comment) }
      format.xml  { head :ok }
    end
  end
end
