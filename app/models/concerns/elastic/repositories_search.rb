module Elastic
  module RepositoriesSearch
    extend ActiveSupport::Concern

    included do
      include Elasticsearch::Git::Repository

      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')
    end

    module ClassMethods
      def repositories_count
        Project.cached_count
      end

      def import
        Project.find_each do |project|
          if project.repository.exists? && !project.repository.empty?
            project.repository.index_commits
            project.repository.index_blobs
          end
        end
      end
    end

    def repository_id
      project.id
    end

    def client_for_indexing
      self.__elasticsearch__.client
    end
  end
end
