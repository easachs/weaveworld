class CreateCharacter < ActiveRecord::Migration[8.0]
  def change
    create_table :characters do |t|
      t.string :name
      t.text :description
      t.string :role
      t.references :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
