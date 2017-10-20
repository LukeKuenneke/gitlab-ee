class Profiles::SlacksController < Profiles::ApplicationController
  include ServicesHelper

  skip_before_action :authenticate_user!

  layout 'application'

  def edit
    if current_user
      @projects = disabled_projects
    end
  end

  def slack_link
    project = disabled_projects.find(params[:project_id])

    respond_to do |format|
      format.json { render json: { add_to_slack_link: add_to_slack_link(project, current_application_settings.slack_app_id) } }
    end
  end

  private

  def disabled_projects
    current_user
    .authorized_projects(Gitlab::Access::MASTER)
    .with_slack_application_disabled
  end
end
