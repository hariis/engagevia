class UsersController < ApplicationController
  # GET /users/new
  # GET /users/new.xml

  layout "application"

  before_filter :load_user_using_perishable_token, :only => [:activate]
  before_filter :is_admin , :only => [:index,:destroy]
  before_filter :require_user, :except => [:new, :create, :activate, :resendactivation, :resendnewactivation, :update_name]

  def is_admin
    current_user && current_user.admin?
  end

  def index
    if current_user && current_user.admin?
      @users = User.find(:all)
    else
      redirect_to root_url
    end
  end

  def show
   if current_user && current_user.activated?
     @user = current_user
     if @user.tag_list == ""
        @user.tag_list = "Click here to Add"
      end
   else     
     force_logout
     redirect_to login_path
   end
  end

  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = current_user
  end

  # POST /users
  # POST /users.xml

  def resendnewactivation
    render
  end

  def resendactivation
    @user = User.find_by_email(params[:email])
    if @user
        @user.deliver_account_confirmation_instructions!
        flash[:notice] = "Instructions to confirm your account have been emailed to you. " +
        "Please check your email and click on the activation link."
        redirect_to root_url
    else
      flash[:notice] = "No user was found with that email address."
      redirect_to root_url
    end
  end


  def create
    @user = User.find_by_email(params[:user][:email])
    if @user
      if @user.non_member?
          assign_user_object
      elsif !@user.activated?
          flash[:error] = "Your account already exists. Please activate your account"
          redirect_to root_url
          return
      else
          flash[:error] = "Your account already exists. Please login or use reset password"
          redirect_to login_url
          return
      end
    else      
      @user = User.new
      @user.email = params[:user][:email]
      assign_user_object
    end

    respond_to do |format|
   
      #if @user.save
      if @user.save_without_session_maintenance #dont login and goto to home page
        @user.add_role("member")
        @user.add_role("admin") if User.find(:all).size < 3 # first two users are admin
        @user.deliver_account_confirmation_instructions!
        flash[:status] = "An email has been sent to confirm that we have your correct email address. <br/>" +
        "Please check your Inbox and also sometimes your Spam folder :( and click on the activation link."
        
        format.html { redirect_to(root_url) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end


  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = current_user    
    assign_user_object
    respond_to do |format|
      if @user.update_attributes(params[:user])
        #flash[:notice] = "Successfully updated profile."
        format.html { redirect_to(user_url) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy

    respond_to do |format|
      format.html { redirect_to(users_url) }
      format.xml  { head :ok }
    end
  end

 def activate
    flash[:notice] = "Thanks for confirming your acocunt.<br/>To maintain security, Please login and you will be on your way."
    @user.activate #set the activated at
    #login him in
    redirect_to login_url #redirect him to dash board
  end

 def method_missing(methodname, *args)
#       @methodname = methodname
#       @args = args
#       if controller_name == "users" && methodname != :controller
#         flash[:error] = 'Could not locate the user you requested'
#       end
#       if methodname != :controller
#         render 'posts/404', :status => 404, :layout => false
#       else
#         controller = 'posts'
#       end      
 end

 def update_name
   @user = User.find_by_unique_id(params[:uid]) if params[:uid]
   if @user.non_member? && @user.first_name == 'firstname'
      #require the first name and last name
      if params[:first_name] != nil && params[:first_name] != ""
        @user.first_name = params[:first_name]
      else
        render :update do |page|
          page.replace_html "name-request-status", "Please identify yourself!"
        end
        return
      end
      if params[:last_name] != nil && params[:last_name] != ""
        @user.last_name = params[:last_name]
      else
        render :update do |page|
          page.replace_html "new-comment-status", "Please identify yourself!"
        end
       return
      end
      #If everything is ok
      if @user.save
        flash[:notice] = "Welcome #{@user.display_name}!"
        render :update do |page|
          page.visual_effect :blind_up, 'name-request'
          page.replace_html "non-member-name", flash[:notice]
          page.select("non-member-name").each { |b| b.visual_effect :highlight, :startcolor => "#f3add0",
											:endcolor => "#ffffff", :duration => 5.0 }
        end
      end
    end
 end
 def set_user_tag_list
    @user = User.find(params[:id]) if params[:id]
    @user.tag_list = params[:value]
    @user.save

    if params[:value] && params[:value].length > 0
      render :text => @user.tag_list
    else
      render :text => "Click here to Add"
    end
  end
private
  def load_user_using_perishable_token
    #You can lengthen that limit by changing:
    #@user = User.find_using_perishable_token(params[:activation_code], 2.hours)
    #Or just set it to 0 to disable the limit all together:
    @user = User.find_using_perishable_token(params[:activation_code], 0)

    unless @user
      flash[:error] = "We're sorry, but we could not locate your account. <br/>" +
        "If you are having issues try copying and pasting the link " +
        "from your email into your browser. " 
      redirect_to root_url
    end
 end
 def assign_user_object
      @user.username = params[:user][:username]
      @user.screen_name = params[:user][:screen_name]
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      @user.avatar = params[:user][:avatar] if params[:user][:avatar] != nil
      @user.first_name = params[:user][:first_name]
      @user.last_name = params[:user][:last_name]
      @user.facebook_link = params[:user][:facebook_link]
      @user.linked_in_link = params[:user][:linked_in_link]
      @user.blog_link = params[:user][:blog_link]
      @user.tag_list = params[:user][:tag_list]
 end
end