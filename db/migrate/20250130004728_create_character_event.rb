class CreateCharacterEvent < ActiveRecord::Migration[8.0]
  def change
    create_table :character_events do |t|
      t.references :event, null: false, foreign_key: true
      t.references :character, null: false, foreign_key: true

      t.timestamps
    end
  end
end
