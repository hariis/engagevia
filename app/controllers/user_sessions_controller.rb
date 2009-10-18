class UserSessionsController < ApplicationController
  before_filter :require_no_user, :only => [:new, :create]
  before_filter :require_user, :only => [:destroy]
  def new
    @user_session = UserSession.new
    @user_session.email = flash[:email]
  end

  def create  
    @user = User.find_by_email(params[:user_session][:email])

    if !@user.nil?
        if @user.member?
            if @user.activated?
                @user_session = UserSession.new(params[:user_session])
                if @user_session.save
                  flash[:notice] = "Welcome #{@user.display_name}! "
                  redirect_back_or_default(posts_url)
                else
                  render :action => 'new'
                end
            else
                flash[:notice] = "Your account is not activated. Please activate your account"
                redirect_to root_url
            end
        else
          #How can this happen? logged in but not a member - Hacked in, perhaps
          flash[:notice] = "We're sorry, but we could not locate your account.<br/> Please signup first, if you haven't already."
          redirect_to root_url
        end
    else
      flash[:notice] = "We're sorry, but we could not locate your account. Please signup first."
      redirect_to root_url
    end
  end
   
  def destroy  
    @user_session = UserSession.find  
    @user_session.destroy  
    flash[:notice] = "Successfully logged out."
    redirect_to root_url
  end  
  def method_missing(methodname, *args)
#       @methodname = methodname
#       @args = args
#       if methodname == :controller
#         controller = 'posts'
#       else
#         render 'posts/404', :status => 404, :layout => false
#       end
   end
end
