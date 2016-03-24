class UpdateAllMirrorsWorker
  include Sidekiq::Worker

  def perform
    fail_stuck_mirrors!

    Project.mirror.each { |project| project.update_mirror(force: false) }
  end

  def fail_stuck_mirrors!
    stuck = Project.mirror.
      with_import_status(:started).
      where('mirror_last_update_at < ?', 1.day.ago)

    stuck.find_each(batch_size: 50) do |project|
      project.import_fail
      project.update_attribute(:import_error, 'The mirror update took too long to complete.')
    end
  end
end
