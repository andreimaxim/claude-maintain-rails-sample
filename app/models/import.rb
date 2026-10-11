require "csv"

# A CSV of notes for one notebook. A preview reads and validates the rows without
# saving anything. Applying validates them again and saves the import with every
# row's note, or saves nothing.
class Import < ApplicationRecord
  HEADERS = %w[ title body_html doi annotation reminder_epoch ]
  MAXIMUM_SIZE = 100.kilobytes
  MAXIMUM_ROWS = 100

  Row = Struct.new(:line, :note, :annotation)

  belongs_to :notebook
  has_many :notes, dependent: :nullify

  validate :csv_is_importable, on: :create

  # Reads one byte past the limit, which is enough to reject a larger file.
  def file=(upload)
    self.csv = upload.read(MAXIMUM_SIZE + 1).to_s.force_encoding(Encoding::UTF_8)
  end

  def csv
    @csv.to_s
  end

  def csv=(text)
    @csv = text.to_s
    @rows = nil
  end

  def rows
    parse unless @rows
    @rows
  end

  # The reader's annotations by source line.
  def annotations
    rows.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |row, annotations|
      annotations[row.line] = row.annotation
    end
  end

  # Validates the file and every row without saving. Returns whether the import
  # can be applied, leaving the errors on the import and each row's note.
  def preview
    valid? && rows.map { |row| row.note.valid? }.all?
  end

  def apply
    return false if invalid?

    transaction do
      save!
      rows.each do |row|
        return false unless row.note.save
      end
    end

    true
  end

  def receipt
    CSV.generate do |csv|
      csv << %w[ title doi ]
      notes.includes(:citation).order(:id).each do |note|
        citation = note.citation
        csv << [ note.title, citation && citation[:id] ]
      end
    end
  end

  private
    def parse
      @rows, @headers, @problem = [], nil, nil
      return if csv.bytesize > MAXIMUM_SIZE || !csv.valid_encoding?

      reader = CSV.new(csv.delete_prefix("\uFEFF").encode(universal_newline: true))
      citations = {}
      next_line = 1

      reader.each do |fields|
        line, next_line = next_line, next_line + reader.line.count("\n")

        if @headers.nil?
          @headers = fields.map { |field| field.to_s.strip }
          break if @headers != HEADERS
        elsif fields.size != HEADERS.size && fields.any?
          @problem = "line #{line} has #{fields.size} fields instead of #{HEADERS.size}"
          break
        elsif fields.any?
          @rows << build_row(line, fields, citations)
          break if @rows.size > MAXIMUM_ROWS
        end
      end
    rescue CSV::MalformedCSVError => error
      @problem = "it is not valid CSV (#{error.message})"
    end

    # Rows naming the same DOI share one citation, so it is created only once.
    def build_row(line, fields, citations)
      title, body_html, doi, annotation, reminder_epoch = fields.map { |field| field.to_s.strip }
      citation = citations[doi] ||= Citation.find_or_initialize_by(doi: doi) if doi.present?

      note = Note.new(notebook: notebook, import: self, title: title, body: body_html, citation: citation,
        annotation: annotation.presence, reminder_epoch: reminder_epoch.presence)

      Row.new(line, note, annotation.presence)
    end

    def csv_is_importable
      rows

      if csv.empty?
        errors.add(:csv, :blank)
      elsif csv.bytesize > MAXIMUM_SIZE
        errors.add(:csv, "must be #{ActiveSupport::NumberHelper.number_to_human_size(MAXIMUM_SIZE)} or smaller")
      elsif !csv.valid_encoding?
        errors.add(:csv, "must be UTF-8 text")
      elsif @problem
        errors.add(:csv, "cannot be read because #{@problem}")
      elsif @headers != HEADERS
        errors.add(:csv, "must start with the header row #{HEADERS.join(",")}")
      elsif rows.empty?
        errors.add(:csv, "must contain at least one note")
      elsif rows.size > MAXIMUM_ROWS
        errors.add(:csv, "must contain #{MAXIMUM_ROWS} notes or fewer")
      end
    end
end
