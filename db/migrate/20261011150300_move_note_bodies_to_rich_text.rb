class MoveNoteBodiesToRichText < ActiveRecord::Migration[7.0]
  def up
    select_rows("SELECT id, body FROM notes WHERE body <> ''").each do |id, body|
      html = "<div>#{ERB::Util.html_escape(body).gsub(/\r?\n/, "<br>")}</div>"

      execute <<~SQL
        INSERT INTO action_text_rich_texts (record_type, record_id, name, body, created_at, updated_at)
        VALUES ('Note', #{id}, 'body', #{quote(html)}, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
      SQL
    end

    remove_column :notes, :body
  end

  def down
    add_column :notes, :body, :text

    select_rows("SELECT record_id, body FROM action_text_rich_texts WHERE record_type = 'Note' AND name = 'body'").each do |id, html|
      execute "UPDATE notes SET body = #{quote(ActionText::Content.new(html).to_plain_text)} WHERE id = #{id}"
    end

    execute "DELETE FROM action_text_rich_texts WHERE record_type = 'Note' AND name = 'body'"
  end
end
