class UuidArticle < ActiveRecord::Base
  include ActiveUUID::UUID

  has_many :tags
end
