class AddNewToEvents < ActiveRecord::Migration[8.0]
  def change
    add_column :events, :new, :boolean, default: true
  end
end
