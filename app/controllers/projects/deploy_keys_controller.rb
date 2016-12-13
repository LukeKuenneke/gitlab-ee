class Projects::DeployKeysController < Projects::ApplicationController
  include ProtectedBranchesHelper
  respond_to :html

  # Authorize
  before_action :authorize_admin_project!

  layout "project_settings"

  def index
    @key = DeployKey.new
    @protected_branch = @project.protected_branches.new
    @protected_branches = @project.protected_branches.order(:name).page(params[:page])
    set_index_vars
    load_gon_index(@project)
  end

  def new
    redirect_to namespace_project_deploy_keys_path(@project.namespace, @project)
  end

  def create
    @key = DeployKey.new(deploy_key_params)
    set_index_vars

    if @key.valid? && @project.deploy_keys << @key
      log_audit_event(@key.title, action: :create)

      redirect_to namespace_project_deploy_keys_path(@project.namespace, @project)
    else
      render "index"
    end
  end

  def enable
    load_key
    Projects::EnableDeployKeyService.new(@project, current_user, params).execute
    log_audit_event(@key.title, action: :create)

    redirect_to namespace_project_deploy_keys_path(@project.namespace, @project)
  end

  def disable
    load_key
    @project.deploy_keys_projects.find_by(deploy_key_id: params[:id]).destroy
    log_audit_event(@key.title, action: :destroy)

    redirect_back_or_default(default: { action: 'index' })
  end

  protected

  def set_index_vars
    @enabled_keys           ||= @project.deploy_keys

    @available_keys         ||= current_user.accessible_deploy_keys - @enabled_keys
    @available_project_keys ||= current_user.project_deploy_keys - @enabled_keys
    @available_public_keys  ||= DeployKey.are_public - @enabled_keys

    # Public keys that are already used by another accessible project are already
    # in @available_project_keys.
    @available_public_keys -= @available_project_keys
  end

  def deploy_key_params
    params.require(:deploy_key).permit(:key, :title)
  end

  def log_audit_event(key_title, options = {})
    AuditEventService.new(current_user, @project, options).
      for_deploy_key(key_title).security_event
  end

  def load_key
    @key ||= current_user.accessible_deploy_keys.find(params[:id])
  end
end
