require 'gitlab' # Load lib/gitlab.rb as soon as possible

class Settings < Settingslogic
  source ENV.fetch('GITLAB_CONFIG') { "#{Rails.root}/config/gitlab.yml" }
  namespace Rails.env

  class << self
    def gitlab_on_standard_port?
      on_standard_port?(gitlab)
    end

    # get host without www, thanks to http://stackoverflow.com/a/6674363/1233435
    def get_host_without_www(url)
      url = URI.encode(url)
      uri = URI.parse(url)
      uri = URI.parse("http://#{url}") if uri.scheme.nil?
      host = uri.host.downcase
      host.start_with?('www.') ? host[4..-1] : host
    end

    def build_gitlab_ci_url
      if on_standard_port?(gitlab)
        custom_port = nil
      else
        custom_port = ":#{gitlab.port}"
      end
      [ gitlab.protocol,
        "://",
        gitlab.host,
        custom_port,
        gitlab.relative_url_root
      ].join('')
    end

    def build_pages_url
      base_url(pages).join('')
    end

    def build_gitlab_shell_ssh_path_prefix
      user_host = "#{gitlab_shell.ssh_user}@#{gitlab_shell.ssh_host}"

      if gitlab_shell.ssh_port != 22
        "ssh://#{user_host}:#{gitlab_shell.ssh_port}/"
      else
        if gitlab_shell.ssh_host.include? ':'
          "[#{user_host}]:"
        else
          "#{user_host}:"
        end
      end
    end

    def build_base_gitlab_url
      base_url(gitlab).join('')
    end

    def build_gitlab_url
      (base_url(gitlab) + [gitlab.relative_url_root]).join('')
    end

    def kerberos_protocol
      kerberos.https ? "https" : "http"
    end

    def kerberos_port
      kerberos.use_dedicated_port ? kerberos.port : gitlab.port
    end

    # Curl expects username/password for authentication. However when using GSS-Negotiate not credentials should be needed.
    # By inserting in the Kerberos dedicated URL ":@", we give to curl an empty username and password and GSS auth goes ahead
    # Known bug reported in http://sourceforge.net/p/curl/bugs/440/ and http://curl.haxx.se/docs/knownbugs.html
    def build_gitlab_kerberos_url
      [ kerberos_protocol,
        "://:@",
        gitlab.host,
        ":#{kerberos_port}",
        gitlab.relative_url_root
      ].join('')
    end

    def alternative_gitlab_kerberos_url?
      kerberos.enabled && (build_gitlab_kerberos_url != build_gitlab_url)
    end

    # check that values in `current` (string or integer) is a contant in `modul`.
    def verify_constant_array(modul, current, default)
      values = default || []
      if !current.nil?
        values = []
        current.each do |constant|
          values.push(verify_constant(modul, constant, nil))
        end
        values.delete_if { |value| value.nil? }
      end
      values
    end

    # check that `current` (string or integer) is a contant in `modul`.
    def verify_constant(modul, current, default)
      constant = modul.constants.find{ |name| modul.const_get(name) == current }
      value = constant.nil? ? default : modul.const_get(constant)
      if current.is_a? String
        value = modul.const_get(current.upcase) rescue default
      end
      value
    end

    private

    def base_url(config)
      custom_port = on_standard_port?(config) ? nil : ":#{config.port}"
      [ config.protocol,
        "://",
        config.host,
        custom_port
      ]
    end

    def on_standard_port?(config)
      config.port.to_i == (config.https ? 443 : 80)
    end
  end
end

# Default settings
Settings['ldap'] ||= Settingslogic.new({})
Settings.ldap['enabled'] = false if Settings.ldap['enabled'].nil?
Settings.ldap['sync_time'] = 3600 if Settings.ldap['sync_time'].nil?
Settings.ldap['schedule_sync_daily'] = 1 if Settings.ldap['schedule_sync_daily'].nil?
Settings.ldap['schedule_sync_hour'] = 1 if Settings.ldap['schedule_sync_hour'].nil?
Settings.ldap['schedule_sync_minute'] = 30  if Settings.ldap['schedule_sync_minute'].nil?

# backwards compatibility, we only have one host
if Settings.ldap['enabled'] || Rails.env.test?
  if Settings.ldap['host'].present?
    # We detected old LDAP configuration syntax. Update the config to make it
    # look like it was entered with the new syntax.
    server = Settings.ldap.except('sync_time')
    Settings.ldap['servers'] = {
      'main' => server
    }
  end

  Settings.ldap['servers'].each do |key, server|
    server = Settingslogic.new(server)
    server['label'] ||= 'LDAP'
    server['block_auto_created_users'] = false if server['block_auto_created_users'].nil?
    server['allow_username_or_email_login'] = false if server['allow_username_or_email_login'].nil?
    server['active_directory'] = true if server['active_directory'].nil?
    server['attributes'] = {} if server['attributes'].nil?
    server['provider_name'] ||= "ldap#{key}".downcase
    server['sync_time'] = 3600 if server['sync_time'].nil?
    server['provider_class'] = OmniAuth::Utils.camelize(server['provider_name'])
    Settings.ldap['servers'][key] = server
  end
end


Settings['omniauth'] ||= Settingslogic.new({})
Settings.omniauth['enabled']      = false if Settings.omniauth['enabled'].nil?
Settings.omniauth['auto_sign_in_with_provider'] = false if Settings.omniauth['auto_sign_in_with_provider'].nil?
Settings.omniauth['allow_single_sign_on'] = false if Settings.omniauth['allow_single_sign_on'].nil?
Settings.omniauth['block_auto_created_users'] = true if Settings.omniauth['block_auto_created_users'].nil?
Settings.omniauth['auto_link_ldap_user'] = false if Settings.omniauth['auto_link_ldap_user'].nil?

Settings.omniauth['providers']  ||= []

# Fill out omniauth-gitlab settings. It is needed for easy set up GHE or GH by just specifying url.

github_default_url = "https://github.com"
github_settings = Settings.omniauth['providers'].find { |provider| provider["name"] == "github"}

if github_settings
  # For compatibility with old config files (before 7.8)
  # where people dont have url in github settings
  if github_settings['url'].blank?
    github_settings['url'] = github_default_url
  end

  if github_settings["url"].include?(github_default_url)
    github_settings["args"]["client_options"] = OmniAuth::Strategies::GitHub.default_options[:client_options]
  else
    github_settings["args"]["client_options"] = {
      "site" =>          File.join(github_settings["url"], "api/v3"),
      "authorize_url" => File.join(github_settings["url"], "login/oauth/authorize"),
      "token_url" =>     File.join(github_settings["url"], "login/oauth/access_token")
    }
  end
end

Settings['shared'] ||= Settingslogic.new({})
Settings.shared['path'] = File.expand_path(Settings.shared['path'] || "shared", Rails.root)

Settings['issues_tracker']  ||= {}

#
# GitLab
#
Settings['gitlab'] ||= Settingslogic.new({})
Settings.gitlab['default_projects_limit'] ||= 10
Settings.gitlab['default_branch_protection'] ||= 2
Settings.gitlab['default_can_create_group'] = true if Settings.gitlab['default_can_create_group'].nil?
Settings.gitlab['default_theme'] = Gitlab::Themes::APPLICATION_DEFAULT if Settings.gitlab['default_theme'].nil?
Settings.gitlab['host']       ||= 'localhost'
Settings.gitlab['ssh_host']   ||= Settings.gitlab.host
Settings.gitlab['https']        = false if Settings.gitlab['https'].nil?
Settings.gitlab['port']       ||= Settings.gitlab.https ? 443 : 80
Settings.gitlab['relative_url_root'] ||= ENV['RAILS_RELATIVE_URL_ROOT'] || ''
Settings.gitlab['protocol']   ||= Settings.gitlab.https ? "https" : "http"
Settings.gitlab['email_enabled'] ||= true if Settings.gitlab['email_enabled'].nil?
Settings.gitlab['email_from'] ||= "gitlab@#{Settings.gitlab.host}"
Settings.gitlab['email_display_name'] ||= "GitLab"
Settings.gitlab['email_reply_to'] ||= "noreply@#{Settings.gitlab.host}"
Settings.gitlab['base_url']   ||= Settings.send(:build_base_gitlab_url)
Settings.gitlab['url']        ||= Settings.send(:build_gitlab_url)
Settings.gitlab['user']       ||= 'git'
Settings.gitlab['user_home']  ||= begin
  Etc.getpwnam(Settings.gitlab['user']).dir
rescue ArgumentError # no user configured
  '/home/' + Settings.gitlab['user']
end
Settings.gitlab['time_zone']  ||= nil
Settings.gitlab['signup_enabled'] ||= true if Settings.gitlab['signup_enabled'].nil?
Settings.gitlab['signin_enabled'] ||= true if Settings.gitlab['signin_enabled'].nil?
Settings.gitlab['twitter_sharing_enabled'] ||= true if Settings.gitlab['twitter_sharing_enabled'].nil?
Settings.gitlab['restricted_visibility_levels'] = Settings.send(:verify_constant_array, Gitlab::VisibilityLevel, Settings.gitlab['restricted_visibility_levels'], [])
Settings.gitlab['username_changing_enabled'] = true if Settings.gitlab['username_changing_enabled'].nil?
Settings.gitlab['issue_closing_pattern'] = '((?:[Cc]los(?:e[sd]?|ing)|[Ff]ix(?:e[sd]|ing)?|[Rr]esolv(?:e[sd]?|ing)) +(?:(?:issues? +)?%{issue_ref}(?:(?:, *| +and +)?)|([A-Z]*-\d*))+)' if Settings.gitlab['issue_closing_pattern'].nil?
Settings.gitlab['default_projects_features'] ||= {}
Settings.gitlab['webhook_timeout'] ||= 10
Settings.gitlab['max_attachment_size'] ||= 10
Settings.gitlab['session_expire_delay'] ||= 10080
Settings.gitlab.default_projects_features['issues']         = true if Settings.gitlab.default_projects_features['issues'].nil?
Settings.gitlab.default_projects_features['merge_requests'] = true if Settings.gitlab.default_projects_features['merge_requests'].nil?
Settings.gitlab.default_projects_features['wiki']           = true if Settings.gitlab.default_projects_features['wiki'].nil?
Settings.gitlab.default_projects_features['snippets']       = false if Settings.gitlab.default_projects_features['snippets'].nil?
Settings.gitlab.default_projects_features['builds']         = true if Settings.gitlab.default_projects_features['builds'].nil?
Settings.gitlab.default_projects_features['visibility_level']    = Settings.send(:verify_constant, Gitlab::VisibilityLevel, Settings.gitlab.default_projects_features['visibility_level'], Gitlab::VisibilityLevel::PRIVATE)
Settings.gitlab['repository_downloads_path'] = File.join(Settings.shared['path'], 'cache/archive') if Settings.gitlab['repository_downloads_path'].nil?
Settings.gitlab['restricted_signup_domains'] ||= []
Settings.gitlab['import_sources'] ||= ['github','bitbucket','gitlab','gitorious','google_code','fogbugz','git']


#
# CI
#
Settings['gitlab_ci'] ||= Settingslogic.new({})
Settings.gitlab_ci['shared_runners_enabled'] = true if Settings.gitlab_ci['shared_runners_enabled'].nil?
Settings.gitlab_ci['all_broken_builds']     = true if Settings.gitlab_ci['all_broken_builds'].nil?
Settings.gitlab_ci['add_pusher']            = false if Settings.gitlab_ci['add_pusher'].nil?
Settings.gitlab_ci['url']                   ||= Settings.send(:build_gitlab_ci_url)
Settings.gitlab_ci['builds_path']           = File.expand_path(Settings.gitlab_ci['builds_path'] || "builds/", Rails.root)

#
# Reply by email
#
Settings['incoming_email'] ||= Settingslogic.new({})
Settings.incoming_email['enabled']    = false if Settings.incoming_email['enabled'].nil?
Settings.incoming_email['port']       = 143 if Settings.incoming_email['port'].nil?
Settings.incoming_email['ssl']        = false if Settings.incoming_email['ssl'].nil?
Settings.incoming_email['start_tls']  = false if Settings.incoming_email['start_tls'].nil?
Settings.incoming_email['mailbox']    = "inbox" if Settings.incoming_email['mailbox'].nil?

#
# Build Artifacts
#
Settings['artifacts'] ||= Settingslogic.new({})
Settings.artifacts['enabled']      = true if Settings.artifacts['enabled'].nil?
Settings.artifacts['path']         = File.expand_path(Settings.artifacts['path'] || File.join(Settings.shared['path'], "artifacts"), Rails.root)
Settings.artifacts['max_size']    ||= 100 # in megabytes

#
# Pages
#
Settings['pages'] ||= Settingslogic.new({})
Settings.pages['enabled']         = false if Settings.pages['enabled'].nil?
Settings.pages['path']            = File.expand_path(Settings.pages['path'] || File.join(Settings.shared['path'], "pages"), Rails.root)
Settings.pages['host']            ||= "example.com"
Settings.pages['https']           = false if Settings.pages['https'].nil?
Settings.pages['port']            ||= Settings.pages.https ? 443 : 80
Settings.pages['protocol']        ||= Settings.pages.https ? "https" : "http"
Settings.pages['url']             ||= Settings.send(:build_pages_url)

#
# Git LFS
#
Settings['lfs'] ||= Settingslogic.new({})
Settings.lfs['enabled']      = true if Settings.lfs['enabled'].nil?
Settings.lfs['storage_path'] = File.expand_path(Settings.lfs['storage_path'] || File.join(Settings.shared['path'], "lfs-objects"), Rails.root)

#
# Gravatar
#
Settings['gravatar'] ||= Settingslogic.new({})
Settings.gravatar['enabled']      = true if Settings.gravatar['enabled'].nil?
Settings.gravatar['plain_url']  ||= 'http://www.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
Settings.gravatar['ssl_url']    ||= 'https://secure.gravatar.com/avatar/%{hash}?s=%{size}&d=identicon'
Settings.gravatar['host']         = Settings.get_host_without_www(Settings.gravatar['plain_url'])

#
# Cron Jobs
#
Settings['cron_jobs'] ||= Settingslogic.new({})
Settings.cron_jobs['stuck_ci_builds_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['stuck_ci_builds_worker']['cron'] ||= '0 0 * * *'
Settings.cron_jobs['stuck_ci_builds_worker']['job_class'] = 'StuckCiBuildsWorker'
Settings.cron_jobs['historical_data_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['historical_data_worker']['cron'] ||= '0 12 * * *'
Settings.cron_jobs['historical_data_worker']['job_class'] = 'HistoricalDataWorker'
Settings.cron_jobs['update_all_mirrors_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['update_all_mirrors_worker']['cron'] ||= '0 * * * *'
Settings.cron_jobs['update_all_mirrors_worker']['job_class'] = 'UpdateAllMirrorsWorker'
Settings.cron_jobs['ldap_sync_worker'] ||= Settingslogic.new({})
Settings.cron_jobs['ldap_sync_worker']['cron'] ||= '30 1 * * *'
Settings.cron_jobs['ldap_sync_worker']['job_class'] = 'LdapSyncWorker'

#
# GitLab Shell
#
Settings['gitlab_shell'] ||= Settingslogic.new({})
Settings.gitlab_shell['path']         ||= Settings.gitlab['user_home'] + '/gitlab-shell/'
Settings.gitlab_shell['hooks_path']   ||= Settings.gitlab['user_home'] + '/gitlab-shell/hooks/'
Settings.gitlab_shell['secret_file'] ||= Rails.root.join('.gitlab_shell_secret')
Settings.gitlab_shell['receive_pack']   = true if Settings.gitlab_shell['receive_pack'].nil?
Settings.gitlab_shell['upload_pack']    = true if Settings.gitlab_shell['upload_pack'].nil?
Settings.gitlab_shell['repos_path']   ||= Settings.gitlab['user_home'] + '/repositories/'
Settings.gitlab_shell['ssh_host']     ||= Settings.gitlab.ssh_host
Settings.gitlab_shell['ssh_port']     ||= 22
Settings.gitlab_shell['ssh_user']     ||= Settings.gitlab.user
Settings.gitlab_shell['owner_group']  ||= Settings.gitlab.user
Settings.gitlab_shell['ssh_path_prefix'] ||= Settings.send(:build_gitlab_shell_ssh_path_prefix)

#
# Backup
#
Settings['backup'] ||= Settingslogic.new({})
Settings.backup['keep_time']  ||= 0
Settings.backup['pg_schema']    = nil
Settings.backup['path']         = File.expand_path(Settings.backup['path'] || "tmp/backups/", Rails.root)
Settings.backup['archive_permissions']          ||= 0600
Settings.backup['upload'] ||= Settingslogic.new({ 'remote_directory' => nil, 'connection' => nil })
# Convert upload connection settings to use symbol keys, to make Fog happy
if Settings.backup['upload']['connection']
  Settings.backup['upload']['connection'] = Hash[Settings.backup['upload']['connection'].map { |k, v| [k.to_sym, v] }]
end
Settings.backup['upload']['multipart_chunk_size'] ||= 104857600
Settings.backup['upload']['encryption'] ||= nil

#
# Git
#
Settings['git'] ||= Settingslogic.new({})
Settings.git['max_size']  ||= 20971520 # 20.megabytes
Settings.git['bin_path']  ||= '/usr/bin/git'
Settings.git['timeout']   ||= 10

# Important: keep the satellites.path setting until GitLab 9.0 at
# least. This setting is fed to 'rm -rf' in
# db/migrate/20151023144219_remove_satellites.rb
Settings['satellites'] ||= Settingslogic.new({})
Settings.satellites['path'] = File.expand_path(Settings.satellites['path'] || "tmp/repo_satellites/", Rails.root)


#
# Kerberos
#
Settings['kerberos'] ||= Settingslogic.new({})
Settings.kerberos['enabled'] = false if Settings.kerberos['enabled'].nil?
Settings.kerberos['keytab'] = nil if Settings.kerberos['keytab'].blank? #nil means use default keytab
Settings.kerberos['service_principal_name'] = nil if Settings.kerberos['service_principal_name'].blank? #nil means any SPN in keytab
Settings.kerberos['use_dedicated_port'] = false if Settings.kerberos['use_dedicated_port'].nil?
Settings.kerberos['https'] = Settings.gitlab.https if Settings.kerberos['https'].nil?
Settings.kerberos['port'] ||= Settings.kerberos.https ? 8443 : 8088

#
# Extra customization
#
Settings['extra'] ||= Settingslogic.new({})

#
# Rack::Attack settings
#
Settings['rack_attack'] ||= Settingslogic.new({})
Settings.rack_attack['git_basic_auth'] ||= Settingslogic.new({})
Settings.rack_attack.git_basic_auth['enabled'] = true if Settings.rack_attack.git_basic_auth['enabled'].nil?
Settings.rack_attack.git_basic_auth['ip_whitelist'] ||= %w{127.0.0.1}
Settings.rack_attack.git_basic_auth['maxretry'] ||= 10
Settings.rack_attack.git_basic_auth['findtime'] ||= 1.minute
Settings.rack_attack.git_basic_auth['bantime'] ||= 1.hour

#
# Testing settings
#
if Rails.env.test?
  Settings.gitlab['default_projects_limit']   = 42
  Settings.gitlab['default_can_create_group'] = true
  Settings.gitlab['default_can_create_team']  = false
end

# Force a refresh of application settings at startup
begin
  ApplicationSetting.expire
  Ci::ApplicationSetting.expire
rescue
  # Gracefully handle when Redis is not available. For example,
  # omnibus may fail here during assets:precompile.
end
