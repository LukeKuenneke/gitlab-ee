class LdapSyncWorker
  include Sidekiq::Worker
  include Sidetiq::Schedulable

  # We check if we are in a Sidekiq server process because of a bug in Sidetiq
  # 0.6.1 which was giving Unicorn trouble (throwing a Redis::InheritedError).
  if Gitlab.config.ldap.enabled && Sidekiq.server?
    HOUR = Gitlab.config.ldap.schedule_sync_hour
    MINUTE = Gitlab.config.ldap.schedule_sync_minute

    recurrence { daily.hour_of_day(HOUR).minute_of_hour(MINUTE) }
  end

  def perform
    Rails.logger.info "Performing daily LDAP sync task."
    User.ldap.find_each(batch_size: 100).each do |ldap_user|
      Rails.logger.debug "Syncing user #{ldap_user.username}, #{ldap_user.email}"
      Gitlab::LDAP::Access.allowed?(ldap_user)
    end
  end
end
