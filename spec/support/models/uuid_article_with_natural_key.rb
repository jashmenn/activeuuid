class UuidArticleWithNaturalKey < ActiveRecord::Base
  include ActiveUUID::UUID
  self.table_name = 'uuid_articles'
  natural_key :title
end
