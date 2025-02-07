class Document < ApplicationRecord
  has_one_attached :file  # If using Active Storage
  validates :title, presence: true
end
