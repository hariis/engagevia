class UserSessionsController < ApplicationController
  def new
    @user_session = UserSession.new
  end

  def create  
    @user = User.find_by_email(params[:user_session][:email])

    if @user && @user.activated?
      @user_session = UserSession.new(params[:user_session])
      if @user_session.save
        flash[:notice] = "Successfully logged in."
        redirect_to root_url
      else
        render :action => 'new'
      end
    else
      if @user.nil?
        flash[:notice] = "We're sorry, but we could not locate your account. Please signup"
      else
        flash[:notice] = "Please activate your account and then try logging in"
      end
      redirect_to root_url
    end
  end  
   
  def destroy  
    @user_session = UserSession.find  
    @user_session.destroy  
    flash[:notice] = "Successfully logged out."  
    redirect_to root_url  
  end  

end
