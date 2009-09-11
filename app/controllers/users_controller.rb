class UsersController < ApplicationController
  # GET /users/new
  # GET /users/new.xml

  layout "application"

  before_filter :load_user_using_perishable_token, :only => [:activate]
  before_filter :is_admin , :only => [:index,:destroy]
  before_filter :require_user, :except => [:new, :create, :activate, :resendactivation, :resendnewactivation]

  def is_admin
    current_user.admin?
  end

  def index
    if current_user 
      @users = User.find(:all)
    else
      redirect_to root_url
    end
  end
  def show
   @user = current_user
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
          @user.username = params[:user][:username]
          @user.password = params[:user][:password]
          #@user.password_confirmation = params[:user][:password_confirmation]
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
      @user.username = params[:user][:username]
      @user.email = params[:user][:email]
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end

    respond_to do |format|
   
      #if @user.save
      if @user.save_without_session_maintenance #dont login and goto to home page
        @user.add_role("member")
        @user.add_role("admin") if User.find(:all).size < 3 # first two users are admin
        @user.deliver_account_confirmation_instructions!
        flash[:notice] = "Instructions to confirm your account have been emailed to you. " +
        "Please check your email."
        
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

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "Successfully updated profile."
        format.html { redirect_to(root_url) }
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
    flash[:notice] = "Thanks for confirming your acocunt."
    @user.activate #set the activated at
    #login him in
    redirect_to login_url #redirect him to dash board
  end

 def method_missing(methodname, *args)
       @methodname = methodname
       @args = args
       if controller_name == "users" && methodname != :controller
         flash[:error] = 'Could not locate the user you requested'
       end
       if methodname != :controller
         render 'posts/404', :status => 404, :layout => false
       else
         controller = 'posts'
       end
 end
private
  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:activation_code])
    unless @user
      flash[:error] = "We're sorry, but we could not locate your account. <br/>" +
        "If you are having issues try copying and pasting the link " +
        "from your email into your browser. " 
      redirect_to root_url
    end
 end
 
end