class CreateExports < ActiveRecord::Migration[7.0]
  def change
    create_table :exports do |t|
      t.references :notebook, null: false, foreign_key: true
      t.integer :status, null: false, default: 0
      t.string :job_id
      t.integer :processed_notes_count, null: false, default: 0
      t.integer :total_notes_count
      t.datetime :expires_at
      t.timestamps
    end
  end
end
