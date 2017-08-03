class Projects::MirrorsController < Projects::ApplicationController
  include RepositorySettingsRedirect
  include SafeMirrorParams
  # Authorize
  before_action :authorize_admin_project!, except: [:update_now]
  before_action :authorize_push_code!, only: [:update_now]
  before_action :remote_mirror, only: [:update]
  before_action :check_repository_mirrors_available!

  layout "project_settings"

  def show
    redirect_to_repository_settings(@project)
  end

  def ssh_host_keys
    lookup = SshHostKey.new(project_id: project.id, url: params[:ssh_url])

    if lookup.error.present?
      # Failed to read keys
      render json: { message: lookup.error }, status: 400
    elsif lookup.known_hosts.nil?
      # Still working, come back later
      render body: nil, status: 204
    else
      render json: lookup
    end
  rescue ArgumentError => err
    render json: { message: err.message }, status: 400
  end

  def update
    if @project.update_attributes(safe_mirror_params)
      if @project.mirror?
        @project.force_import_job!

        flash[:notice] = "Mirroring settings were successfully updated. The project is being updated."
      elsif project.previous_changes.key?('mirror')
        flash[:notice] = "Mirroring was successfully disabled."
      else
        flash[:notice] = "Mirroring settings were successfully updated."
      end
    else
      flash[:alert] = @project.errors.full_messages.join(', ').html_safe
    end

    redirect_to_repository_settings(@project)
  end

  def update_now
    if params[:sync_remote]
      @project.update_remote_mirrors
      flash[:notice] = "The remote repository is being updated..."
    else
      @project.force_import_job!
      flash[:notice] = "The repository is being updated..."
    end

    redirect_to_repository_settings(@project)
  end

  private

  def remote_mirror
    @remote_mirror = @project.remote_mirrors.first_or_initialize
  end

  def mirror_params
    params.require(:project).permit(:mirror, :import_url, :mirror_user_id,
                                    :mirror_trigger_builds, remote_mirrors_attributes: [:url, :id, :enabled])
  end

  def safe_mirror_params
    return mirror_params if valid_mirror_user?(mirror_params)

    mirror_params.merge(mirror_user_id: current_user.id)
  end
end
