class CreateImportsAndCitations < ActiveRecord::Migration[7.0]
  def change
    create_table :citations, primary_key: :doi, id: :string do |t|
      t.timestamps
    end

    create_table :imports do |t|
      t.references :notebook, null: false, foreign_key: true
      t.timestamps
    end

    change_table :notes do |t|
      t.references :import, foreign_key: true
      t.string :citation_doi, index: true
      t.text :annotation
      t.bigint :reminder_epoch
    end
    add_foreign_key :notes, :citations, column: :citation_doi, primary_key: :doi
  end
end
