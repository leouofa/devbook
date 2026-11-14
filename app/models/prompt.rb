class Prompt < ApplicationRecord
  belongs_to :project, optional: true
  has_many_attached :files

  validates :title, presence: true

  scope :standalone, -> { where(project_id: nil) }
  scope :recent, -> { order(updated_at: :desc) }
  scope :pinned, -> { where(pinned: true).order(Arel.sql("pinned_position ASC NULLS LAST, updated_at DESC")) }
  scope :search, ->(query) {
    return all if query.blank?
    where("title ILIKE :q OR body ILIKE :q", q: "%#{sanitize_sql_like(query.to_s.strip)}%")
  }

  def toggle_pin!
    if pinned?
      update!(pinned: false, pinned_position: nil)
    else
      max_pos = Prompt.where(pinned: true).maximum(:pinned_position) || 0
      update!(pinned: true, pinned_position: max_pos + 1)
    end
  end
end
