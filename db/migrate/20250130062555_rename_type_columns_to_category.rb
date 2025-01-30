class RenameTypeColumnsToCategory < ActiveRecord::Migration[8.0]
  def change
    rename_column :locations, :type, :category
    rename_column :events, :type, :category
    rename_column :items, :type, :category
  end
end
