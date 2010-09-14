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
  end

  def load_post
    @post = Post.find_by_unique_id(params[:pid]) if params[:pid]
  end  
  
  def new
    @comment = Comment.new
    @parent_comment = Comment.find(params[:pcid])
    respond_to do |format|
      format.html # new.html.erb
      format.xml  {  }
      format.js { 
        render :update do |page|          
          page.show 'reply-to-comment'
          page << "if ( $j('#form_#{@parent_comment.id}').length == 0 )"
          page.insert_html :top, 'reply-to-comment', :partial => 'new'
          page << "if ( $j('#form_#{@parent_comment.id}').length == 1 )"
          page.show "form_#{@parent_comment.id}"
      end
      }  #render_to_facebox
    end
  end
  
  # POST /comments
  # POST /comments.xml
  def create
    @comment = Comment.new
    comment_body = params[:pcid].nil? ? params[:comment_body] : params["comment_body_#{params[:pcid]}"]
    if comment_body != nil && comment_body != ""
      @comment.body = comment_body
    else
      render :update do |page|
        if params[:pcid].nil?
          page.replace_html "new-comment-status", "Please enter your valuable comments"
        else
          page.replace_html "new-reply-comment-status", "Please enter your valuable comments"
        end
      end
      return
    end
    
    @comment.user_id = @user.id
    if params[:pcid] != nil
      @comment.parent_id = params[:pcid]
      @parent_comment = Comment.find(params[:pcid])
    else
      @comment.sticky = params[:sticky_check_box]
    end

    if @post.comments << @comment
      #@comment.touch_root_parent_comment unless params[:pcid].nil?
      update_tags_for(@user) if @post.is_first_comment?(@user)
      @comment.deliver_comment_notification(@post)      
      #@user.join_ec_of(@post.owner) if @post.owner.id != @user.id  
      @user.add_mutually_to_address_book(@post.owner) if @post.owner.id != @user.id 
      render :update do |page|
        if params[:pcid].nil?
          if @comment.sticky?
            @last_viewed_at = @post.last_viewed_at(@user)
            page.insert_html :top, 'sticky-comments', :partial => "/comments/sticky_comment", :object => @comment,  :locals => {:root => 'true',:parent_comment => nil}
          else
            page.insert_html :top, 'comments', :partial => "/comments/comment", :object => @comment,  :locals => {:root => 'true',:parent_comment => nil}

            page.replace_html "comments-heading", "Comments (#{@post.comments.size})"
            page.select("comments-heading").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
                          :endcolor => "#cf6d0f", :duration => 5.0 }
          end
            page.replace_html "new-comment-status", "Thank you for your comment."
            page.replace_html "new-comment-body", ""
        else
            #page.hide 'facebox'            
            page.hide 'reply-to-comment'
            page.hide "form_#{@parent_comment.id}"
            page.insert_html :bottom, "children_for_#{params[:pcid]}", :partial => "/comments/comment", :object => @comment,  :locals => {:root => nil,:parent_comment => @parent_comment}
            page.replace_html "comments-heading", "Comments (#{@post.comments.size})"
            page.select("comments-heading").each { |b| b.visual_effect :highlight, :startcolor => "#fb3f37",
                          :endcolor => "#cf6d0f", :duration => 5.0 }
        end
      end

    else
      page.replace_html "new-comment-status", "There was a problem saving your description. Please refresh and try again."
    end
  end
  
  def create_reply_comment
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
      #@user.join_ec_of(@post.owner) if @post.owner.id != @user.id 
      @user.add_mutually_to_address_book(@post.owner) if @post.owner.id != @user.id 
      #@comment.touch_root_parent_comment
    else
      render :text => "There was a problem saving your description. Please refresh and try again."
    end    
  end

  def set_comment_body
    @comment = @post.comments.find(params[:id])
    @comment.body = params[:value] == "" ? "<i>Comment removed by author</i>" : params[:value]
    @comment.user_id = @user.id if @comment.sticky?
    if @comment.save
      #@comment.touch_root_parent_comment
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
  
  # DELETE /comments/1
  # DELETE /comments/1.xml
  def destroy
    @comment = Comment.find(params[:id])
    @comment.destroy if @comment.owner == @user && @comment.sticky?

    respond_to do |format|
      format.html { redirect_to(@post, @comment) }
      format.xml  { head :ok }
      format.js {
        render :update do |page|
          page.select("sticky_#{@comment.id}").each { |b| b.fade }
          page.remove "sticky_#{@comment.id}"
        end
      }
    end
  end
 private
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