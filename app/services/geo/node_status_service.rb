module Geo
  class NodeStatusService
    include Gitlab::CurrentSettings
    include HTTParty

    KEYS = %w(health repositories_count repositories_synced_count repositories_failed_count lfs_objects_total lfs_objects_synced).freeze

    def call(status_url)
      values =
        begin
          response = self.class.get(status_url, headers: headers, timeout: timeout)

          if response.success?
            response.parsed_response.values_at(*KEYS)
          else
            ["Could not connect to Geo node - HTTP Status Code: #{response.code}"]
          end
        rescue HTTParty::Error, Timeout::Error, SocketError, Errno::ECONNRESET, Errno::ECONNREFUSED => e
          [e.message]
        end

      GeoNodeStatus.new(KEYS.zip(values).to_h)
    end

    private

    def headers
      Gitlab::Geo::BaseRequest.new.headers
    end

    def timeout
      current_application_settings.geo_status_timeout
    end
  end
end
