# A work identified by its DOI, shared by every reader who cites it. Readers'
# own annotations stay on their notes.
class Citation < ApplicationRecord
  has_many :notes, foreign_key: :citation_doi

  validates :doi, format: { with: %r{\A10\.\d{4,9}/\S+\z} }
end
