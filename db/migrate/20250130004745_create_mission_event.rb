class CreateMissionEvent < ActiveRecord::Migration[8.0]
  def change
    create_table :mission_events do |t|
      t.references :event, null: false, foreign_key: true
      t.references :mission, null: false, foreign_key: true

      t.timestamps
    end
  end
end
