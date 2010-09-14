class UsersController < ApplicationController
  # GET /users/new
  # GET /users/new.xml

  layout "application"

  before_filter :load_user_using_perishable_token, :only => [:activate]
  before_filter :is_admin , :only => [:index, :destroy] #:contacts, :groups
  before_filter :require_user, :except => [:new, :create, :activate, :resendactivation, :resendnewactivation, :update_name]

  def is_admin
    if !(current_user && current_user.admin?)
      redirect_to root_url
    end
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
    #if params[:email].empty?
    #  flash[:error] = "Email cannot be blank"
    #  render :action => :resendnewactivation and return
    #end

    @user = User.find_by_email(params[:email])
    if @user
        @user.deliver_account_confirmation_instructions!
        flash[:notice] = "Instructions to confirm your account have been emailed to you. " +
        "Please check your email and click on the activation link."
        redirect_to root_url
    else
      flash[:notice] = "No user was found with that email address."      
      render 'resendnewactivation'
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
      #verify email veracity and proceed only if success
      unless params[:user][:email].blank?
          unless params[:user][:email] =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
              @user.errors.add(:email, "Your email address does not appear to be valid")
          else
              @user.errors.add(:email, "Your email domain name appears to be incorrect") unless validate_email_domain(params[:user][:email])
          end
      else
          @user.errors.add(:email, "cannot be empty")
      end
     #If there are no errors looged then go ahead
      if @user.errors.size == 0
        @user.email = params[:user][:email]
        @user.username = "member"  #currently this field is not used -this is a dummy value
        assign_user_object
      end
    end

    respond_to do |format|
   
      #if @user.save
      if @user.errors.size == 0 && @user.save_without_session_maintenance #dont login and goto to home page
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
   @post = Post.find_by_unique_id(params[:pid]) if params[:pid]
   checkpassword = @user.engagements.count > 1
 
   @error_message = ""
   if @user.non_member?
     #check if user firstname and lastname is available
     if @user.first_name == 'firstname' && @user.last_name == 'lastname'
        if params[:first_name].blank? || params[:last_name].blank? 
            @error_message = "Please identify yourself with both your first and last name"
        end
     end
     if checkpassword && params[:password].blank?
       @error_message = "Please choose a password! This will help you access all your conversations from one place."
     end
   
     #all the information is available     
     if @error_message.blank?
        @user.first_name = params[:first_name] ||  @user.first_name
        @user.last_name = params[:last_name] || @user.last_name
        
        if checkpassword
            @user.password = params[:password]
            @user.password_confirmation = params[:password]
            @user.activated_at = Time.now.utc
            @user.username = "member"
            @user.remove_role("non_member")
            @user.add_role("member")
        end
     end
   
   render :update do |page|    
      if @error_message.blank? && @user.save
        flash[:notice] = "Welcome #{@user.display_name}!"
        page.visual_effect :blind_up, 'name-request'
        #show the top right corner options
        if checkpassword
            page.replace_html "band-actions", :partial => 'posts/member_band_actions'
            page.select("band-actions").each { |b| b.visual_effect :highlight, :startcolor => "#f3add0",
                        :endcolor => "#ffffff", :duration => 5.0 }
        end
        #remove the x is a member     
      else        
          page.replace_html "name-request-status", @error_message        
      end
   end
   
  end
 end
 
 
 
 def set_user_tag_list
    @user = User.find(params[:id]) if params[:id]
    @user.user_id = @user.id
    @user.tag_list = params[:value]
    @user.save

    if params[:value] && params[:value].length > 0
      render :text => @user.tag_list
    else
      render :text => "Click here to Add"
    end
  end
 
 def groups   
   group = params[:id].nil? ? 'ic' : params[:id]
   if group.nil? || group == 'ic'
     render 'groups_ic'
   else
     render 'groups_ec'
   end
 end
 
 def display_profile
   @user = User.find(params[:id])
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
#      @user.username = params[:user][:screen_name]
#      @user.screen_name = params[:user][:screen_name]
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      @user.avatar = params[:user][:avatar] if params[:user][:avatar] != nil
      @user.first_name = params[:user][:first_name]
      @user.last_name = params[:user][:last_name]
      @user.facebook_link = params[:user][:facebook_link]
      @user.linked_in_link = params[:user][:linked_in_link]
      @user.blog_link = params[:user][:blog_link]
      @user.user_id = @user.id
      @user.tag_list = params[:user][:tag_list]
 end 
end