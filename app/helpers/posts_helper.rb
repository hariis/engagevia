module PostsHelper
  def get_comments_count(post)
    pluralize(post.comments.count, "comment")
  end

  def get_participants_count(post)
    pluralize(post.engagements.count, "participant")
  end

  def last_updated_by(post)
    all_comments = post.comments.find(:all, :order => 'updated_at desc')
    all_comments.size > 0 ? all_comments[0].owner.display_name : post.owner.display_name
  end

  def get_joined_participants_count(post)
    participants_count = 0
    post.engagements.each do |engagement|
       participants_count = participants_count + 1 if engagement.joined == true
    end
    return participants_count
  end
     
end
