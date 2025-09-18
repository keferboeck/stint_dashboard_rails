class TempUpload < ApplicationRecord
  belongs_to :user
  has_many :temp_recipients, dependent: :destroy

  before_validation :ensure_token

  private
  def ensure_token
    self.token ||= SecureRandom.urlsafe_base64(24)
  end
end