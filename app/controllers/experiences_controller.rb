class ExperiencesController < ApplicationController

   
 def capture_experience
    respond_to do |format|
        format.html
        #format.xml { render :xml => @post }
        format.js { render_to_facebox }
    end
 end
 
 def store_experience
     experience = Experience.new
     experience.title = params[:title]
     experience.description = params[:description]
     experience.othercomments = params[:othercomments] || ""
     experience.email = params[:email]  || ""
     experience.name = params[:name]  || ""
     
     #store_location
     Notifier.deliver_send_experience(experience)
     #redirect_back_or_default(root_url)
     #redirect_to :controller => 'posts', :action => 'admin'
     #return
 end
end
