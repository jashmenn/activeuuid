class UuidArticle < ActiveRecord::Base
  include ActiveUUID::UUID

  validates :id, uniqueness: true, length: { in: 32..40 }, unless: :new_record?

end
