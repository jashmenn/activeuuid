class AddArrayToArticles < ActiveRecord::Migration
  def change
    add_column :articles, :some_array, :integer, array: true
  end
end
