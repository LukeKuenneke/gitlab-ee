class RepositoryUpdateMirrorWorker
  UpdateMirrorError = Class.new(StandardError)

  include Sidekiq::Worker
  include Gitlab::ShellAdapter

  # Retry not neccessary. It will try again at the next update interval.
  sidekiq_options queue: :project_mirror, retry: false

  attr_accessor :project, :repository, :current_user

  def perform(project_id)
    begin
      project = Project.find(project_id)

      return unless project

      @current_user = project.mirror_user || project.creator

      result = Projects::UpdateMirrorService.new(project, @current_user).execute
      if result[:status] == :error
        project.mark_import_as_failed(result[:message])
        Rails.logger.error("RepositoryUpdateMirrorWorker: import failed for project #{project.id}")
        return
      end

      project.import_finish
    rescue => ex
      if project
        project.mark_import_as_failed("We're sorry, a temporary error occurred, please try again.")
        Rails.logger.error("RepositoryUpdateMirrorWorker: import failed for project #{project.id}")
        raise UpdateMirrorError, "#{ex.class}: #{Gitlab::UrlSanitizer.sanitize(ex.message)}"
      end
    end
  end
end
