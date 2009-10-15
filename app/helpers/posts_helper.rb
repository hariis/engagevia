module PostsHelper
  def get_comments_count(post)
    pluralize(post.comments.count, "comment")
  end

  def get_participants_count(post)
    pluralize(post.engagements.count, "participant")
  end
end
