class Campaign < ApplicationRecord
  has_many :emails, dependent: :destroy

  STATUSES = %w[PENDING SCHEDULED SENT FAILED].freeze
  validates :status, inclusion: { in: STATUSES }
  validates :template_name, presence: true
  validates :subject, presence: true

  scope :due, -> { where(status: 'SCHEDULED').where('scheduled_at <= ?', Time.current) }
end