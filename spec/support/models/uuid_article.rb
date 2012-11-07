class UuidArticle < ActiveRecord::Base
  include ActiveUUID::UUID
end
