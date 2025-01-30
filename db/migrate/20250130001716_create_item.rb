class CreateItem < ActiveRecord::Migration[8.0]
  def change
    create_table :items do |t|
      t.string :name
      t.text :description
      t.string :type
      t.references :character, null: false, foreign_key: true

      t.timestamps
    end
  end
end
