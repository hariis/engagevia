class GroupsController < ApplicationController
 
  before_filter :redirect_to_error 
  
  def redirect_to_error
    render 'posts/404', :status => 404, :layout => false and return
  end
    
  # POST /groups
  # POST /groups.xml
  def create
    unless params[:post_id].empty?
      #we are creating from post's participants here
      @post_owner = User.find_by_unique_id(params[:uid])
      if !@post_owner.nil? && !params[:group_name].empty?
        @group = Group.new(:user_id => @post_owner.id , :name => params[:group_name].strip)
      end    
    end
        
    if @group.save
        if add_contacts_from_post_participants(params[:post_id])
          error = ""
        else
          error = "Error! Please Try again!"
        end
    else
          error = "Error! Please Try again!"
    end
    render :update do |page|
         if error.blank?
           page.replace_html 'group-name', @group.name
         else
           page.replace_html 'group-name-status', error
         end        
    end
  end

  def add_contacts_from_post_participants(post_id)
    begin
        @post = Post.find_by_id(post_id)
        unless @post.nil?
          @post.get_all_participants.each do |p|
            m = Membership.find_or_create_by_user_id_and_group_id(:user_id => p.id, :group_id => @group.id) if p.id != @post_owner.id
          end
        end
        return true
    end
  end  
 
end
