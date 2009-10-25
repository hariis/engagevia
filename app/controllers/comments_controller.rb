class CommentsController < ApplicationController
  # GET /comments
  # GET /comments.xml
  
  before_filter :load_post
  before_filter :load_user
  def method_missing(methodname, *args)
       @methodname = methodname
       @args = args
       if methodname == :controller
         controller = 'posts'
       else
         render 'posts/404', :status => 404, :layout => false
       end
   end
  
  def load_user
     if current_user && current_user.activated?
        @user = current_user
      else
        #load the user based on the unique id
        @user = User.find_by_unique_id(params[:uid]) if params[:uid]
      end
      if @user.nil?
        flash[:error] = "Your identity could not be confirmed from the link that you provided. <br/> Please request the post owner to resend the link."
        force_logout
        redirect_to login_path
      end
      return
  end
  def load_post
    @post = Post.find(params[:post_id]) if params[:post_id]
  end  
  
   # POST /comments
  # POST /comments.xml
  def create
    @comment = Comment.new
    if params[:comment][:body] != nil && params[:comment][:body] != ""
      @comment.body = params[:comment][:body]
    else
      render :update do |page|
        page.replace_html "new-comment-status", "Please enter your valuable comments"
      end
      return
    end
    if @user.non_member? && @user.first_name == 'firstname'
      #require the first name and last name
      if params[:first_name] != nil && params[:first_name] != ""
        @user.first_name = params[:first_name]
      else
        render :update do |page|
          page.replace_html "new-comment-status", "Please identify yourself! <br/> Your information is available only to this conversation participants."
        end
        return
      end
      if params[:last_name] != nil && params[:last_name] != ""
        @user.last_name = params[:last_name]
      else
        render :update do |page|
          page.replace_html "new-comment-status", "Please identify yourself! <br/> Your information is available only to this conversation participants."
        end
       return
      end
      #If everything is ok
      @user.save
    end
    @comment.user_id = @user.id
    if params[:id] != nil
      @comment.parent_id = params[:id]
    end

    if @post.comments << @comment
      @comment.deliver_comment_notification(@post)
      render :update do |page|
        page.insert_html :bottom, 'comments', :partial => "/comments/comment", :object => @comment,  :locals => {:root => 'true',:parent_comment => nil}
        
        page.replace_html "comments-heading", "Comments (#{@post.comments.size})"
        page.select("comments-heading").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
											:endcolor => "#cf6d0f", :duration => 5.0 }
        page.replace_html "new-comment-status", "Thank you for your comment."
        page.replace_html "new-comment-body", ""
      end

    else
      page.replace_html "new-comment-status", "There was a problem saving your description. Please refresh and try again."
    end
  end
  def create_old
    if params[:value] == "Click here to add your comment" || params[:value] == ""
      render :text => "Click here to add your comment"
      return
    end
    @comment = Comment.new
    @comment.body = params[:value]
    @comment.user_id = @user.id
    if params[:id] != nil
      @comment.parent_id = params[:id]
    end

    if @post.comments << @comment
      render :text => @comment.body
      @comment.deliver_comment_notification(@post)   
    else
      render :text => "There was a problem saving your description. Please refresh and try again."
    end    
  end

  def set_comment_body
    @comment = @post.comments.find(params[:id])
    @comment.body = params[:value] == "" ? "<i>Comment removed by author</i>" : params[:value]
    if @comment.save
      render :text => @comment.body
    else
      render :text => "There was a problem saving your description. Please refresh and try again."
    end
  end
  # PUT /comments/1
  # PUT /comments/1.xml
  def update
    @comment = @post.comments.find(params[:id])

    respond_to do |format|
      if @comment.update_attributes(params[:comment])
        format.html { redirect_to(@post, @comment) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @comment.errors, :status => :unprocessable_entity }
      end
    end
  end
  private
  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = @post.comments.find(params[:id])
    @comment.destroy if @comment.owner == @user

    respond_to do |format|
      format.html { redirect_to(@post, @comment) }
      format.xml  { head :ok }
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
end
