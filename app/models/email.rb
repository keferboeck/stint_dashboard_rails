class Email < ApplicationRecord
  belongs_to :campaign
  STATUSES = %w[PENDING SENT FAILED].freeze
  validates :status, inclusion: { in: STATUSES }
  validates :address, presence: true
end