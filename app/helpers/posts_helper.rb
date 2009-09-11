module PostsHelper
  def get_comments_count(post)
    pluralize(post.comments.count, "comment")
  end
end
