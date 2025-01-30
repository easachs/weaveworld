class CreateFact < ActiveRecord::Migration[8.0]
  def change
    create_table :facts do |t|
      t.text :text
      t.references :story, null: false, foreign_key: true

      t.timestamps
    end
  end
end
