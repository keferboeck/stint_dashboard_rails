# frozen_string_literal: true
namespace :scheduler do
  desc "Process scheduled campaigns (respects AppSetting flags)"
  task run: :environment do
    Scheduler::ProcessScheduledCampaigns.call
  end
end