class ExperiencesController < ApplicationController

   
 def capture_experience
    respond_to do |format|
        format.html
        #format.xml { render :xml => @post }
        format.js { render_to_facebox }
    end
 end
 
 def store_experience
     render :update do |page|       
         if params[:description] != ""
             experience = Experience.new
             experience.description = params[:description]
             experience.othercomments = params[:othercomments] || ""
             experience.email = params[:email]  || "Not provided"
             experience.name = params[:name]  || "Anonymous"

             Notifier.deliver_send_experience(experience)
             page.hide 'facebox'
             #flash[:notice] = "Thank you very much for sharing your feedback."
         else
             page.replace_html "feedback-status", "Please add some details and share again"       
         end
     end
 end
end
