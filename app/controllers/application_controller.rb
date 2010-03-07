# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  protect_from_forgery # See ActionController::RequestForgeryProtection for details
  include FaceboxRender
  include ExceptionNotifiable

  ExceptionNotifier.exception_recipients = %w(hrajagopal@yahoo.com satish.fnu@gmail.com)

  # Scrub sensitive parameters from your log
   filter_parameter_logging :password
  
  helper_method :current_user  
  
  private  
    def current_user_session  
      return @current_user_session if defined?(@current_user_session)  
      @current_user_session = UserSession.find  
    end  
      
    def current_user  
      @current_user = current_user_session && current_user_session.record  
    end  

    def require_user
      unless current_user
        store_location
        flash[:notice] = "You must be logged in to access this page"
        redirect_to new_user_session_url
        return false
      end
    end

    def require_no_user
      if current_user
        store_location
        #flash[:notice] = "You must be logged out to access this page"
        force_logout
        return true
        #redirect_to account_url
        #return false
      end
    end

    def store_location
      session[:return_to] = request.env["HTTP_REFERER"] || request.request_uri
    end

    def redirect_back_or_default(default)
      redirect_to(session[:return_to] || default)
      session[:return_to] = nil
    end

    def force_logout
      @user_session = UserSession.find
      @user_session.destroy if @user_session
      session[:return_to] = nil
    end
    #validating email
    def validate_emails(emails)
            #Parse the string into an array
              valid_emails =[]
              valid_emails = string_to_array(emails)

              offending_email = ""
              addresses = []
              valid_emails.each {|email|
                      if validate_simple_email(email)
                             addresses << email
                              next
                      elsif  validate_ab_style_email(email)                                
                                addresses << email
                                next
                      else
                          offending_email = email
                              break
                      end
              }

              if offending_email == ""
                      return true
              else
                  @invalid_emails_message = "Email address: #{offending_email} incorrect.	Please try again."
                      return false
              end
         end
     def validate_simple_email(email)
          emailRE= /\A[\w\._%-]+@[\w\.-]+\.[a-zA-Z]{2,4}\z/
          return email =~ emailRE
     end
     def validate_ab_style_email(email)
          email.gsub!(/\A"/, '\1')
           str = email.split(/ /)
           str.delete_if{|x| x== ""}
           email = str[str.size-1].delete "<>"
           emailRE= /\A[\w\._%-]+@[\w\.-]+\.[a-zA-Z]{2,4}\z/
           return email =~ emailRE
     end
     def string_to_array(stringitem)
                  #Parse the string into an array
                valid_array =[]
                return if stringitem == nil
                valid_array.concat(stringitem.split(/,/))

                # delete any blank emails
                valid_array = valid_array.delete_if { |t| t.empty? }

                # trim spaces around all tags
                valid_array = valid_array.map! { |t| t.strip }

                # downcase all tags
                valid_array = valid_array.map! { |t| t.downcase }

                # extract ab-style emails
                 valid_array = valid_array.map! do |t|
                   if t.include?('<')
                     t.gsub!(/\A"/, '\1')
                     str = t.split(/ /)
                     str.delete_if{|x| x== ""}
                     t = str[str.size-1].delete "<>"
                   else
                     t
                  end
                 end

                # remove duplicates
                valid_array = valid_array.uniq               
      end
     def is_admin
      current_user.has_role?('admin')
     end

     #Related to auto-tagging the users 
    def update_tags_for_all_invitees(invitees)
       admin = User.get_admin_user
       invitees.each do |invitee|
          admin.user_id = invitee.id
          admin.post_id = @post.id
          admin.set_associated_tag_list = @post.tag_list
        end
    end
    
end
