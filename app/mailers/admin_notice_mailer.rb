class AdminNoticeMailer < ApplicationMailer
  DOTS = {
    critical: "🔴",
    success:  "🟢",
    warning:  "🟡",
    info:     "⚫️",
    blue:     "🔵",
    neutral:  "⚪️"
  }.freeze

  def subject_with_dot(severity, text)
    "#{DOTS[severity.to_sym] || DOTS[:info]} #{text}"
  end

  # No signature change: you can keep calling .event(to:, title:, message:, severity:)
  # If you *do* want to pass kind:, it will be used; otherwise we auto-detect in the view.
  def event(to:, title:, message:, severity: :info, kind: nil)
    @heading = title
    @message = message
    @kind    = kind
    derive_actor_and_time(@message)
    mail(to: to, subject: subject_with_dot(severity, title))
  end

  def settings_updated(to:, changed_keys:, actor:)
    @heading = "Settings updated"
    @changed_keys = changed_keys
    @actor = actor
    mail(to: to, subject: subject_with_dot(:info, "Settings updated: #{changed_keys.join(', ')}"))
  end

  private

  # Extracts "by <email> at <time>" from your existing message string, if present.
  def derive_actor_and_time(message)
    return if message.blank?
    if (m = message.match(/by\s+(?<actor>\S+@\S+)\s+at\s+(?<time>.+)\.?$/))
      @actor    = m[:actor]
      @when_str = m[:time]
    end
  end
end