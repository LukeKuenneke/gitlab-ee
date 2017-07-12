class Profiles::SlacksController < Profiles::ApplicationController
  skip_before_action :authenticate_user!

  layout 'application'

  def edit
    if current_user
      @projects = current_user
                    .authorized_projects(Gitlab::Access::MASTER)
                    .with_slack_application_disabled
    end
  end
end
