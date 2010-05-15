diff --cc app/controllers/comments_controller.rb
index 31c0d94,b223dfe..0000000
--- a/app/controllers/comments_controller.rb
+++ b/app/controllers/comments_controller.rb
@@@ -75,11 -82,9 +82,15 @@@ class CommentsController < ApplicationC
  
      if @post.comments << @comment
        @comment.deliver_comment_notification(@post)
++<<<<<<< HEAD
 +      update_contact(@post.owner)
 +      update_contact(@user)      
 +      
++=======
+     
++>>>>>>> 2de515201337bbe3279bad5126f27aae5f6c71b5
        render :update do |page|
 -        if params[:pcid].nil?
 +        if params[:pcid].nil?            
              page.insert_html :top, 'comments', :partial => "/comments/comment", :object => @comment,  :locals => {:root => 'true',:parent_comment => nil}
  
              page.replace_html "comments-heading", "Comments (#{@post.comments.size})"
