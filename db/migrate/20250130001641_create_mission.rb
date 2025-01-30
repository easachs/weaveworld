class CreateMission < ActiveRecord::Migration[8.0]
  def change
    create_table :missions do |t|
      t.string :name
      t.text :description
      t.string :status
      t.references :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
