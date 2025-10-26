class AdminNoticeMailer < ApplicationMailer
  DOTS = {
    critical: "🔴",  # destructive ops
    success:  "🟢",  # all good
    warning:  "🟡",  # partial issues
    info:     "⚫️",  # generic/system
    blue:     "🔵",  # ops/infra
    neutral:  "⚪️"   # low-importance
  }.freeze

  def subject_with_dot(severity, text)
    "#{DOTS[severity.to_sym] || DOTS[:info]} #{text}"
  end

  # generic event (hold, purge, cron, etc.)
  def event(to:, title:, message:, severity: :info)
    @heading = title
    @message = message
    mail(to: to, subject: subject_with_dot(severity, title))
  end

  # settings updated
  def settings_updated(to:, changed_keys:, actor:)
    @heading = "Settings updated"
    @changed_keys = changed_keys
    @actor = actor
    mail(to: to, subject: subject_with_dot(:info, "Settings updated: #{changed_keys.join(', ')}"))
  end
end