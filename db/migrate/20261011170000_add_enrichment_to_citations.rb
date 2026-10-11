class AddEnrichmentToCitations < ActiveRecord::Migration[7.0]
  def change
    change_table :citations do |t|
      t.string :title
      t.string :source_url
      t.integer :enrichment_status
      t.string :enrichment_error
    end
  end
end
