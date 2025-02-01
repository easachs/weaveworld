class AddNewToRecords < ActiveRecord::Migration[8.0]
  def change
    add_column :characters, :new, :boolean, default: true
    add_column :locations, :new, :boolean, default: true
    add_column :missions, :new, :boolean, default: true
    add_column :facts, :new, :boolean, default: true
  end
end
