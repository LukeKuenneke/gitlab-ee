class Profiles::SlacksController < Profiles::ApplicationController
  skip_before_action :authenticate_user!

  layout 'application'

  def edit
    if current_user
      @projects = disabled_projects
    end
  end

  def slack_link
    p 'HELLO LUUKE'
    p params[:project_id]

    project = disabled_projects.find(params[:project_id]) || {}

    render add_to_slack_link: add_to_slack_link(project)
  end

  private

  def disabled_projects
    current_user
    .authorized_projects(Gitlab::Access::MASTER)
    .with_slack_application_disabled
  end
end
