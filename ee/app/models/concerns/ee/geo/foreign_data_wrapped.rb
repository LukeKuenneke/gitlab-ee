module EE
  module Geo
    module ForeignDataWrapped
      extend ActiveSupport::Concern

      class_methods do
        def geo_fdw
          instance = self.clone
          instance.table_name = "#{::Gitlab::Geo.fdw_schema}.#{self.table_name}"

          # Used by ActiveRecord::ConnectionAdapters::ConnectionHandler#establish_connection
          # to link the class to a connection in the ConnectionPool
          def instance.name
            table_name
          end

          instance.establish_connection Rails.configuration.geo_database

          instance
        end
      end
    end
  end
end
