class Prompt < ApplicationRecord
  belongs_to :project, optional: true
  has_many_attached :files

  validates :title, presence: true

  scope :standalone, -> { where(project_id: nil) }
  scope :recent, -> { order(updated_at: :desc) }
  scope :search, ->(query) {
    return all if query.blank?
    where("title ILIKE :q OR body ILIKE :q", q: "%#{sanitize_sql_like(query.to_s.strip)}%")
  }
end
