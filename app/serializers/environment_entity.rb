class EnvironmentEntity < Grape::Entity
  include RequestAwareEntity

  expose :id
  expose :name
  expose :state
  expose :external_url
  expose :environment_type
  expose :last_deployment, using: DeploymentEntity
  expose :stop_action?

  expose :metrics_path, if: -> (environment, _) { environment.has_metrics? } do |environment|
    metrics_namespace_project_environment_path(
      environment.project.namespace,
      environment.project,
      environment)
  end

  expose :environment_path do |environment|
    namespace_project_environment_path(
      environment.project.namespace,
      environment.project,
      environment)
  end

  expose :stop_path do |environment|
    stop_namespace_project_environment_path(
      environment.project.namespace,
      environment.project,
      environment)
  end

  expose :terminal_path, if: ->(environment, _) { environment.deployment_service_ready? } do |environment|
    can?(request.current_user, :admin_environment, environment.project) &&
      terminal_namespace_project_environment_path(
        environment.project.namespace,
        environment.project,
        environment)
  end

  expose :rollout_status_path, if: ->(environment, _) { environment.deployment_service_ready? } do |environment|
    can?(request.current_user, :read_deploy_board, environment.project) &&
      status_namespace_project_environment_path(
        environment.project.namespace,
        environment.project,
        environment,
        format: :json)
  end

  expose :created_at, :updated_at
end
