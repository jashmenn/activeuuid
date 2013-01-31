class UuidArticle < ActiveRecord::Base
  include ActiveUUID::UUID

  validates :id, presence: true, uniqueness: true, length: { in: 32..40 }, unless: :new_record?
  validates :another_uuid, presence: true, uniqueness: true, length: { in: 32..40 }, unless: :new_record?

end
