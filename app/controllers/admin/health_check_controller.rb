class Admin::HealthCheckController < Admin::ApplicationController
  def show
<<<<<<< HEAD
    checks = ['standard']
    checks << 'geo' if Gitlab::Geo.secondary?

    @errors = HealthCheck::Utils.process_checks(checks)
=======
    @errors = HealthCheck::Utils.process_checks(['standard'])
>>>>>>> ce/9-5-stable
    @failing_storage_statuses = Gitlab::Git::Storage::Health.for_failing_storages
  end

  def reset_storage_health
    Gitlab::Git::Storage::CircuitBreaker.reset_all!
    redirect_to admin_health_check_path,
                notice: _('Git storage health information has been reset')
  end
end
