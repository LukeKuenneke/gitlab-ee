class Projects::MirrorsController < Projects::ApplicationController
  # Authorize
  before_action :authorize_admin_project!, except: [:update_now]
  before_action :authorize_push_code!, only: [:update_now]

  layout "project_settings"

  def show

  end

  def update
    if @project.update_attributes(mirror_params)
      if @project.mirror?
        @project.update_mirror

        flash[:notice] = "Mirroring settings were successfully updated. The project is being updated."
      elsif @project.mirror_changed?
        flash[:notice] = "Mirroring was successfully disabled."
      else
        flash[:notice] = "Mirroring settings were successfully updated."
      end

      redirect_to namespace_project_mirror_path(@project.namespace, @project)
    else
      render :show
    end
  end

  def update_now
    @project.update_mirror

    flash[:notice] = "The repository is being updated..."
    redirect_back_or_default(default: namespace_project_path(@project.namespace, @project))
  end

  private

  def mirror_params
    params.require(:project).permit(:mirror, :import_url, :mirror_user_id, :mirror_trigger_builds)
  end
end
