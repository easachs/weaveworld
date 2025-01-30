class CreateMissionCharacter < ActiveRecord::Migration[8.0]
  def change
    create_table :mission_characters do |t|
      t.string :role
      t.references :mission, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true

      t.timestamps
    end
  end
end
