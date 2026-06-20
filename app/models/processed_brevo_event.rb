class ProcessedBrevoEvent < ApplicationRecord
  validates :campaign_id, presence: true, uniqueness: true
end
