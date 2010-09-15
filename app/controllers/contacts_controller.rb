class ContactsController < ApplicationController
 
  layout "application"
  before_filter :check_activated_member, :only => [:index]
  before_filter :is_admin, :only => [:migrate_existing_contacts]
  before_filter :redirect_to_error, :except => [:migrate_existing_contacts, :index]
  
  #-----------------------------------------------------------------------------------------------------
  def redirect_to_error
    render 'posts/404', :status => 404, :layout => false and return
  end
  
  #-----------------------------------------------------------------------------------------------------
  def check_activated_member
    unless current_user && current_user.activated?
      flash[:notice] = "Please login to access this page."
      #redirect_to root_path
      redirect_to login_path
    end
  end
  
  #-----------------------------------------------------------------------------------------------------
  def is_admin
    unless current_user && current_user.admin?
      redirect_to root_url
    end
  end
  
  #-----------------------------------------------------------------------------------------------------
  def migrate_existing_contacts
      Group.delete_all
      Membership.delete_all
      
      @posts = Post.find(:all)
      @posts.each do |post|
        
        engagements = Engagement.find(:all, :conditions => ["post_id = ?", post.id])
        if engagements.size > 1
          engagements.each do |engagement|
            if engagement.user_id != engagement.invited_by
                invitee = User.find_by_id(engagement.user_id)
                inviter = User.find_by_id(engagement.invited_by)
                inviter.add_mutually_to_address_book(invitee)                 
            end
          end
        end
        
        if post.comments.count > 0
            comments = post.comments.find(:all)
            unless comments.nil?
              comments.each do |comment|
                if comment.owner != post.owner
                  comment.owner.add_mutually_to_address_book(post.owner)
                end
              end
            end
        end        
     end
     #redirect_to :controller => 'contacts', :action => 'index'
     redirect_to contacts_path
  end

  #-----------------------------------------------------------------------------------------------------
  # GET /contacts
  # GET /contacts.xml
  def index
    @contacts = current_user.get_address_book_contacts
     
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @contacts }
    end
  end
  
end
