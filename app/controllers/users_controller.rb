class UsersController < ApplicationController
  # GET /users/new
  # GET /users/new.xml
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
    @user = User.new(params[:user])

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
    if @user.update_attributes(params[:user])
       flash[:notice] = 'Successfully created profile.'
    end

    respond_to do |format|
      @user.deliver_account_confirmation_instructions!
      if @user.save
        flash[:notice] = "Instructions to confirm your account have been emailed to you. " +
        "Please check your email."
        #flash[:notice] = 'Registration successfull.'
        format.html { redirect_to(root_path) }
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
