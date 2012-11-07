class CreateUuidArticles < ActiveRecord::Migration
  def change
    create_table :uuid_articles, :id => false do |t|
      t.uuid :id, :primary_key => true
      t.string :title
      t.text :body
      t.uuid :another_uuid

      t.timestamps
    end
  end
end
