class UsersController < ApplicationController
  # GET /users/new
  # GET /users/new.xml

  before_filter :load_user_using_perishable_token, :only => [:activate]
  
  #test code: delete it

  def index
    @users = User.find(:all)
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
  def create1
    #@user = User.new(params[:user])

    @user = User.new
    @user.username = params[:user][:username]
    @user.email = params[:user][:email]
    @user.password = params[:user][:password]
    @user.password_confirmation = params[:user][:password_confirmation]


    respond_to do |format|
      if @user.save
        flash[:notice] = "Registration successful."  
        format.html { redirect_to(root_url) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end


  
  def create
    #@random = ActiveSupport::SecureRandom.hex(10)
    #@user = User.find_by_email("dummy@gmail.com")
    #@user = User.new(params[:user])
    #if @user.update_attributes(params[:user])
    #   flash[:notice] = 'Successfully created profile.'
    #end

    @user = User.find_by_email(params[:user][:email])
    if @user
      if @user.non_member?
          @user.username = params[:user][:username]
          @user.password = params[:user][:password]
          #@user.password_confirmation = params[:user][:password_confirmation]
      elsif !@user.activated?
          flash[:notice] = "Your account already exists. Please active your account"
          redirect_to root_url
          return
      else
          flash[:notice] = "Your account already exists. Please login or use reset password"
          redirect_to login_url
          return
      end
    else
      #@user = User.new(params[:user])
      @user = User.new
      @user.username = params[:user][:username]
      @user.email = params[:user][:email]
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
    end
    
    respond_to do |format|
      @user.add_role("member")
      @user.add_role("admin") if User.find(:all).size < 3 # first two users are admin

      if @user.save
      #if @user.save_without_session_maintenance dont login and goto to home page
        @user.deliver_account_confirmation_instructions!
        flash[:notice] = "Instructions to confirm your account have been emailed to you. " +
        "Please check your email."
        #flash[:notice] = 'Registration successfull.'
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
end

 def activate
    flash[:notice] = "Thanks for confirming your acocunt."
    @user.activate #set the activated at
    #login him in    
    redirect_to root_url #redirect him to dash board
  end

private
  def load_user_using_perishable_token
    @user = User.find_using_perishable_token(params[:activation_code])
    unless @user
      flash[:notice] = "We're sorry, but we could not locate your account." +
        "If you are having issues try copying and pasting the URL " +
        "from your email into your browser or restarting the " +
        "reset password process."
      redirect_to root_url
    end

    #if @user.activated?
    #  flash[:notice] = "You have already activated your account."
    #  redirect_to root_url
    #end
 end