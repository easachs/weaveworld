class CreateMissionLocation < ActiveRecord::Migration[8.0]
  def change
    create_table :mission_locations do |t|
      t.string :role
      t.references :mission, null: false, foreign_key: true
      t.references :location, null: false, foreign_key: true

      t.timestamps
    end
  end
end
