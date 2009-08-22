module PostsHelper
  def GetCommentCount(post)
    post.comments.count
  end
end
