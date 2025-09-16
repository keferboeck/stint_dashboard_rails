class DashboardController < ApplicationController
  # ApplicationController already has before_action :authenticate_user!
  def index
    # Put any lightweight data you want to show on the landing page here.
    @user   = current_user
    @roles  = User.roles.keys # ["admin","manager","viewer"] if you used enum
  end
end