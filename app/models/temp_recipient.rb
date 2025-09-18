class TempRecipient < ApplicationRecord
  belongs_to :temp_upload
  validates :email, presence: true
end