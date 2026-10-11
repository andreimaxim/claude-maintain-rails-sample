class CreateNotes < ActiveRecord::Migration[7.0]
  def change
    create_table :notes do |t|
      t.references :notebook, null: false, foreign_key: true
      t.string :title, null: false
      t.text :body
      t.integer :status, null: false, default: 0

      t.timestamps
    end
  end
end
