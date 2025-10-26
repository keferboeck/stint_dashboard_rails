class ApplicationMailer < ActionMailer::Base
  default from: "no-reply@stint.co"
  layout "stint_mailer"
  helper :mailer

  private

  def utm_defaults(term: "footer", content: "default")
    {
      source: "saas",
      medium: "email",
      campaign: "stint",
      term: term,
      content: content
    }
  end
end