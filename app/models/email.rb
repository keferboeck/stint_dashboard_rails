class Email < ApplicationRecord
  belongs_to :campaign
  STATUSES = %w[PENDING SENT FAILED].freeze
  validates :status, inclusion: { in: STATUSES }
  validates :address, presence: true

  scope :sent_last_24h, -> { where(status: 'SENT').where("sent_at >= ?", 24.hours.ago) }
end