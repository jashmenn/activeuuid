class UuidArticleWithNamespace < ActiveRecord::Base
  include ActiveUUID::UUID
  self.table_name = 'uuid_articles'
  natural_key :title
  uuid_namespace "45e676ea-8a43-4ffe-98ca-c142b0062a83" # a random UUID
end
