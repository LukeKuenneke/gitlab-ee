if Gitlab::LDAP::Config.enabled?
  module OmniAuth::Strategies
    Gitlab::LDAP::Config.servers.each do |server|
      # do not redeclare LDAP
      next if server['provider_name'] == 'ldap'
      const_set(server['provider_class'], Class.new(LDAP))
    end
  end

  OmniauthCallbacksController.class_eval do
    Gitlab::LDAP::Config.servers.each do |server|
      alias_method server['provider_name'], :ldap
    end
  end
end

OmniAuth.config.full_host = Settings.gitlab['base_url']
OmniAuth.config.allowed_request_methods = [:post]
#In case of auto sign-in, the GET method is used (users don't get to click on a button)
OmniAuth.config.allowed_request_methods << :get if Gitlab.config.omniauth.auto_sign_in_with_provider.present?
OmniAuth.config.before_request_phase do |env|
  OmniAuth::RequestForgeryProtection.new(env).call
end

if Gitlab.config.omniauth.enabled
  Gitlab.config.omniauth.providers.each do |provider|
    if provider['name'] == 'kerberos'
      require 'omniauth-kerberos'
    end
  end
end
