module Geo
  class ScheduleRepoUpdateService
    attr_reader :projects

    def initialize(projects)
      @projects = projects
    end

    def execute
      @projects.each do |project|
        GeoRepositoryUpdateWorker.perform_async(project['id'], project['clone_url'])
      end
    end
  end
end
