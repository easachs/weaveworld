class CreateCharacterLocation < ActiveRecord::Migration[8.0]
  def change
    create_table :character_locations do |t|
      t.references :character, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
