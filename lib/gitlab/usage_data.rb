module Gitlab
  class UsageData
    include Gitlab::CurrentSettings

    class << self
      def data(force_refresh: false)
        Rails.cache.fetch('usage_data', force: force_refresh, expires_in: 2.weeks) { uncached_data }
      end

      def uncached_data
        license_usage_data.merge(system_usage_data)
      end

      def to_json(force_refresh: false)
        data(force_refresh: force_refresh).to_json
      end

      def system_usage_data
        {
          counts: {
            boards: Board.count,
            ci_builds: ::Ci::Build.count,
            ci_pipelines: ::Ci::Pipeline.count,
            ci_runners: ::Ci::Runner.count,
            ci_triggers: ::Ci::Trigger.count,
            deploy_keys: DeployKey.count,
            deployments: Deployment.count,
            environments: Environment.count,
            geo_nodes: GeoNode.count,
            groups: Group.count,
            issues: Issue.count,
            keys: Key.count,
            labels: Label.count,
            ldap_group_links: LdapGroupLink.count,
            ldap_keys: LDAPKey.count,
            ldap_users: User.ldap.count,
            lfs_objects: LfsObject.count,
            merge_requests: MergeRequest.count,
            milestones: Milestone.count,
            notes: Note.count,
            pages_domains: PagesDomain.count,
            projects: Project.count,
            projects_prometheus_active: PrometheusService.active.count,
            protected_branches: ProtectedBranch.count,
            releases: Release.count,
            remote_mirrors: RemoteMirror.count,
            services: Service.where(active: true).count,
            snippets: Snippet.count,
            todos: Todo.count,
            uploads: Upload.count,
            web_hooks: WebHook.count
          }.merge(service_desk_counts)
        }
      end

      def service_desk_counts
        return {} unless ::License.current.add_on?('GitLab_ServiceDesk')

        projects_with_service_desk = Project.where(service_desk_enabled: true)

        {
          service_desk_enabled_projects: projects_with_service_desk.count,
          service_desk_issues: Issue.where(project: projects_with_service_desk,
                                           author: User.support_bot,
                                           confidential: true).count
        }
      end

      def license_usage_data
        usage_data = { uuid: current_application_settings.uuid,
                       version: Gitlab::VERSION,
                       active_user_count: User.real.count,
                       mattermost_enabled: Gitlab.config.mattermost.enabled }

        license = ::License.current

        if license
          usage_data[:license_md5] = Digest::MD5.hexdigest(license.data)
          usage_data[:historical_max_users] = ::HistoricalData.max_historical_user_count
          usage_data[:licensee] = license.licensee
          usage_data[:license_user_count] = license.restricted_user_count
          usage_data[:license_starts_at] = license.starts_at
          usage_data[:license_expires_at] = license.expires_at
          usage_data[:license_add_ons] = license.add_ons
          usage_data[:recorded_at] = Time.now
        end

        usage_data
      end
    end
  end
end
