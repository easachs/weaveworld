class CreateStory < ActiveRecord::Migration[8.0]
  def change
    create_table :stories do |t|
      t.string :title
      t.string :genre
      t.text :overview
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
