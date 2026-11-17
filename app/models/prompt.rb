# frozen_string_literal: true

class Prompt < ApplicationRecord
  attr_accessor :skip_versioning

  belongs_to :project, optional: true
  has_many_attached :files
  has_many :versions, -> { order(version_number: :desc) },
           class_name: "PromptVersion",
           dependent: :destroy,
           inverse_of: :prompt

  validates :title, presence: true

  after_create :record_version_snapshot!
  after_update :record_version_snapshot!, unless: :skip_versioning

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

  def latest_version
    versions.reorder(version_number: :desc).first
  end

  def current_version_number
    versions.maximum(:version_number) || 1
  end

  def unversioned_changes?
    latest = latest_version
    return true if latest.nil?

    latest.title != title || latest.body != body
  end

  def record_version_snapshot!
    return unless unversioned_changes?

    next_number = (versions.maximum(:version_number) || 0) + 1
    versions.create!(
      version_number: next_number,
      title: title,
      body: body
    )
  end

  def restore_version!(version)
    transaction do
      record_version_snapshot! if unversioned_changes?
      self.skip_versioning = false
      update!(title: version.title, body: version.body)
      record_version_snapshot!
    end
  end
end
