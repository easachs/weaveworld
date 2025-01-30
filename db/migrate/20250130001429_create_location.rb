class CreateLocation < ActiveRecord::Migration[8.0]
  def change
    create_table :locations do |t|
      t.string :name
      t.text :description
      t.string :type
      t.references :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
