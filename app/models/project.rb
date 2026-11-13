class Project < ApplicationRecord
  has_many :prompts, -> { order(updated_at: :desc) }, dependent: :nullify

  validates :name, presence: true
end
