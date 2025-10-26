class AdminRecipients
  def self.emails
    User.admins.pluck(:email).select(&:present?)
  end
end