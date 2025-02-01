class AddLocationToCharacters < ActiveRecord::Migration[8.0]
  def change
    add_reference :characters, :location, foreign_key: true, null: true
  end
end
