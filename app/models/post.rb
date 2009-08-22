class Post < ActiveRecord::Base
  has_many :comments
  belongs_to :owner, :source => :user
  has_many :engagements
  has_many :participants, :through => :engagements, :source => :user
end
