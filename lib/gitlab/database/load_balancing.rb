module Gitlab
  module Database
    module LoadBalancing
      # The connection proxy to use for load balancing (if enabled).
      cattr_accessor :proxy

      LOG_TAG = 'DB-LB'.freeze

      # The exceptions raised for connection errors.
      CONNECTION_ERRORS = if defined?(PG)
                            [
                              PG::ConnectionBad,
                              PG::ConnectionDoesNotExist,
                              PG::ConnectionException,
                              PG::ConnectionFailure,
                              PG::UnableToSend,
                              # During a failover this error may be raised when
                              # writing to a primary.
                              PG::ReadOnlySqlTransaction
                            ].freeze
                          else
                            [].freeze
                          end

      # Returns the additional hosts to use for load balancing.
      def self.hosts
        hash = ActiveRecord::Base.configurations[Rails.env]['load_balancing']

        if hash
          hash['hosts'] || []
        else
          []
        end
      end

      def self.log(level, message)
        Rails.logger.tagged(LOG_TAG) do
          Rails.logger.send(level, message)
        end
      end

      def self.pool_size
        ActiveRecord::Base.configurations[Rails.env]['pool']
      end

      # Returns true if load balancing is to be enabled.
      def self.enable?
        return false unless ::License.feature_available?(:db_load_balancing)

        program_name != 'rake' && !hosts.empty? && !Sidekiq.server? &&
          Database.postgresql?
      end

      def self.program_name
        @program_name ||= File.basename($0)
      end

      # Configures proxying of requests.
      def self.configure_proxy
        self.proxy = ConnectionProxy.new(hosts)

        # This hijacks the "connection" method to ensure both
        # `ActiveRecord::Base.connection` and all models use the same load
        # balancing proxy.
        ActiveRecord::Base.singleton_class.prepend(ActiveRecordProxy)
      end

      def self.active_record_models
        ActiveRecord::Base.descendants
      end
    end
  end
end
