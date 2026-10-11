class AddSlugAndPreferencesToNotebooks < ActiveRecord::Migration[7.0]
  def up
    add_column :notebooks, :slug, :string
    add_column :notebooks, :preferences, :text

    select_rows("SELECT id, name FROM notebooks").each do |id, name|
      execute "UPDATE notebooks SET slug = #{quote(name.parameterize.presence || "notebook")} WHERE id = #{id}"
    end

    change_column_null :notebooks, :slug, false
  end

  def down
    remove_column :notebooks, :preferences
    remove_column :notebooks, :slug
  end
end
