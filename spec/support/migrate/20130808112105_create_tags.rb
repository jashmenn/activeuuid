class CreateTags < ActiveRecord::Migration
  def change
    create_table :tags, :id => false do |t|
      t.uuid :id, :primary_key => true
      t.string :name
      t.uuid :uuid_article_id
      t.timestamps
    end
  end
end