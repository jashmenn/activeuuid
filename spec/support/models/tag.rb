class Tag < ActiveRecord::Base
  include ActiveUUID::UUID
  belongs_to :uuid_article
end