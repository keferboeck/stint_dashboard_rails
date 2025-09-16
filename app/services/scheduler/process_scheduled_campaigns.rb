# frozen_string_literal: true
module Scheduler
  class ProcessScheduledCampaigns
    def self.call
      s = AppSetting.instance
      if s.scheduling_on_hold || !s.cron_enabled
        Rails.logger.info "[scheduler] skipped (hold=#{s.scheduling_on_hold}, cron=#{s.cron_enabled})"
        return
      end

      # … your existing “find due campaigns and send” code …
      # ProcessDueCampaigns.call or inline logic
    end
  end
end