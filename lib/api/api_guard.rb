# Guard API with OAuth 2.0 Access Token

require 'rack/oauth2'

module API
  module APIGuard
    extend ActiveSupport::Concern

    PRIVATE_TOKEN_HEADER = "HTTP_PRIVATE_TOKEN".freeze
    PRIVATE_TOKEN_PARAM = :private_token
    JOB_TOKEN_HEADER = "HTTP_JOB_TOKEN".freeze
    JOB_TOKEN_PARAM = :job_token

    included do |base|
      # OAuth2 Resource Server Authentication
      use Rack::OAuth2::Server::Resource::Bearer, 'The API' do |request|
        # The authenticator only fetches the raw token string

        # Must yield access token to store it in the env
        request.access_token
      end

      helpers HelperMethods

      install_error_responders(base)
    end

    class_methods do
      # Set the authorization scope(s) allowed for an API endpoint.
      #
      # A call to this method maps the given scope(s) to the current API
      # endpoint class. If this method is called multiple times on the same class,
      # the scopes are all aggregated.
      def allow_access_with_scope(scopes, options = {})
        Array(scopes).each do |scope|
          allowed_scopes << Scope.new(scope, options)
        end
      end

      def allowed_scopes
        @scopes ||= []
      end
    end

    # Helper Methods for Grape Endpoint
    module HelperMethods
      def find_current_user
        user =
          find_user_from_private_token ||
          find_user_from_oauth_token ||
          find_user_from_warden ||
          find_user_by_job_token

        return nil unless user

        raise UnauthorizedError unless Gitlab::UserAccess.new(user).allowed? && user.can?(:access_api)

        user
      end

      def private_token
        params[PRIVATE_TOKEN_PARAM] || env[PRIVATE_TOKEN_HEADER]
      end

      private

      def find_user_from_private_token
        token_string = private_token.to_s
        return nil unless token_string.present?

        user =
          find_user_by_authentication_token(token_string) ||
          find_user_by_personal_access_token(token_string)

        raise UnauthorizedError unless user

        user
      end

      # Invokes the doorkeeper guard.
      #
      # If token is presented and valid, then it sets @current_user.
      #
      # If the token does not have sufficient scopes to cover the requred scopes,
      # then it raises InsufficientScopeError.
      #
      # If the token is expired, then it raises ExpiredError.
      #
      # If the token is revoked, then it raises RevokedError.
      #
      # If the token is not found (nil), then it returns nil
      #
      # Arguments:
      #
      #   scopes: (optional) scopes required for this guard.
      #           Defaults to empty array.
      #
      def find_user_from_oauth_token
        access_token = find_oauth_access_token
        return unless access_token

        find_user_by_access_token(access_token)
      end

      def find_user_by_authentication_token(token_string)
        User.find_by_authentication_token(token_string)
      end

      def find_user_by_personal_access_token(token_string)
        access_token = PersonalAccessToken.find_by_token(token_string)
        return unless access_token

        find_user_by_access_token(access_token)
      end

      # Check the Rails session for valid authentication details
      def find_user_from_warden
        warden.try(:authenticate) if verified_request?
      end

      def warden
        env['warden']
      end

      # Check if the request is GET/HEAD, or if CSRF token is valid.
      def verified_request?
        Gitlab::RequestForgeryProtection.verified?(env)
      end

      def find_user_by_job_token
        return @user_by_job_token if defined?(@user_by_job_token)

        @user_by_job_token =
          if route_authentication_setting[:job_token_allowed]
            token_string = params[JOB_TOKEN_PARAM].presence || env[JOB_TOKEN_HEADER].presence
            Ci::Build.find_by_token(token_string)&.user if token_string
          end
      end

      def route_authentication_setting
        return {} unless respond_to?(:route_setting)

        route_setting(:authentication) || {}
      end

      def find_oauth_access_token
        return @oauth_access_token if defined?(@oauth_access_token)

        token = Doorkeeper::OAuth::Token.from_request(doorkeeper_request, *Doorkeeper.configuration.access_token_methods)
        return @oauth_access_token = nil unless token

        @oauth_access_token = OauthAccessToken.by_token(token)
        raise UnauthorizedError unless @oauth_access_token

        @oauth_access_token.revoke_previous_refresh_token!
        @oauth_access_token
      end

      def find_user_by_access_token(access_token)
        scopes = scopes_registered_for_endpoint

        case AccessTokenValidationService.new(access_token, request: request).validate(scopes: scopes)
        when AccessTokenValidationService::INSUFFICIENT_SCOPE
          raise InsufficientScopeError.new(scopes)

        when AccessTokenValidationService::EXPIRED
          raise ExpiredError

        when AccessTokenValidationService::REVOKED
          raise RevokedError

        when AccessTokenValidationService::VALID
          access_token.user
        end
      end

      def doorkeeper_request
        @doorkeeper_request ||= ActionDispatch::Request.new(env)
      end

      # An array of scopes that were registered (using `allow_access_with_scope`)
      # for the current endpoint class. It also returns scopes registered on
      # `API::API`, since these are meant to apply to all API routes.
      def scopes_registered_for_endpoint
        @scopes_registered_for_endpoint ||=
          begin
            endpoint_classes = [options[:for].presence, ::API::API].compact
            endpoint_classes.reduce([]) do |memo, endpoint|
              if endpoint.respond_to?(:allowed_scopes)
                memo.concat(endpoint.allowed_scopes)
              else
                memo
              end
            end
          end
      end
    end

    module ClassMethods
      private

      def install_error_responders(base)
        error_classes = [MissingTokenError, TokenNotFoundError,
                         ExpiredError, RevokedError, InsufficientScopeError]

        base.__send__(:rescue_from, *error_classes, oauth2_bearer_token_error_handler) # rubocop:disable GitlabSecurity/PublicSend
      end

      def oauth2_bearer_token_error_handler
        proc do |e|
          response =
            case e
            when MissingTokenError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new

            when TokenNotFoundError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Bad Access Token.")

            when ExpiredError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Token is expired. You can either do re-authorization or token refresh.")

            when RevokedError
              Rack::OAuth2::Server::Resource::Bearer::Unauthorized.new(
                :invalid_token,
                "Token was revoked. You have to re-authorize from the user.")

            when InsufficientScopeError
              # FIXME: ForbiddenError (inherited from Bearer::Forbidden of Rack::Oauth2)
              # does not include WWW-Authenticate header, which breaks the standard.
              Rack::OAuth2::Server::Resource::Bearer::Forbidden.new(
                :insufficient_scope,
                Rack::OAuth2::Server::Resource::ErrorMethods::DEFAULT_DESCRIPTION[:insufficient_scope],
                { scope: e.scopes })
            end

          response.finish
        end
      end
    end

    #
    # Exceptions
    #

    MissingTokenError = Class.new(StandardError)
    TokenNotFoundError = Class.new(StandardError)
    ExpiredError = Class.new(StandardError)
    RevokedError = Class.new(StandardError)
    UnauthorizedError = Class.new(StandardError)

    class InsufficientScopeError < StandardError
      attr_reader :scopes
      def initialize(scopes)
        @scopes = scopes
      end
    end
  end
end
