class AddRemindersAndTimeZones < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :time_zone, :string, null: false, default: "UTC"

    change_table :notes do |t|
      t.string :reminder_job_id
      t.datetime :reminder_sent_at
    end
  end
end
