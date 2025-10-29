class DashboardController < ApplicationController
  # ApplicationController already has before_action :authenticate_user!
  def index
    # Put any lightweight data you want to show on the landing page here.
    @user   = current_user
    @roles  = User.roles.keys # ["admin","manager","viewer"] if you used enum

    now = Time.current

    # Top-line stats
    @campaigns_count = Campaign.count
    @scheduled_count = Campaign.where(status: "SCHEDULED")
                               .where("scheduled_at IS NOT NULL AND scheduled_at > ?", now)
                               .count
    @delivered_24h   = Email.where(status: "SENT")
                            .where("sent_at >= ?", 24.hours.ago)
                            .count

    # Recent activity (last 5 campaigns by created_at)
    @recent_campaigns = Campaign.order(created_at: :desc)
                                .includes(:emails)
                                .limit(5)

    # ---- Chart period (defaults to last 7 days inclusive, London wall time) ----
    tz = ActiveSupport::TimeZone["Europe/London"]
    from_param = params[:from].presence
    to_param   = params[:to].presence

    @from_date = begin
                   from_param ? Date.strptime(from_param, "%Y-%m-%d") : (tz.today - 6.days)
                 rescue
                   tz.today - 6.days
                 end

    @to_date = begin
                 to_param ? Date.strptime(to_param, "%Y-%m-%d") : tz.today
               rescue
                 tz.today
               end

    # Normalise in case user swaps them
    if @from_date > @to_date
      @from_date, @to_date = @to_date, @from_date
    end

    from_time = tz.parse(@from_date.strftime("%Y-%m-%d 00:00"))
    to_time   = tz.parse(@to_date.strftime("%Y-%m-%d 23:59:59"))

    sent_scope = Email.where(status: "SENT")
                      .where(sent_at: from_time..to_time)
                      .select(:id, :sent_at)

    # Build daily buckets in Ruby (no extra gems)
    labels = []
    cursor = @from_date
    while cursor <= @to_date
      labels << cursor.strftime("%Y-%m-%d")
      cursor += 1.day
    end

    counts_hash = Hash.new(0)
    sent_scope.find_each do |e|
      day = e.sent_at.in_time_zone(tz).to_date.strftime("%Y-%m-%d")
      counts_hash[day] += 1
    end

    @chart_labels = labels
    @chart_counts = labels.map { |d| counts_hash[d] }
  end
end