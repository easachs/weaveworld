class CreateEvent < ActiveRecord::Migration[8.0]
  def change
    create_table :events do |t|
      t.text :description
      t.text :short
      t.string :type
      t.references :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
