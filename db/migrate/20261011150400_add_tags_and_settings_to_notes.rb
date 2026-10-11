class AddTagsAndSettingsToNotes < ActiveRecord::Migration[7.0]
  def change
    add_column :notes, :tags, :text, null: false, default: "[]"
    add_column :notes, :settings, :jsonb, null: false, default: {}
  end
end
