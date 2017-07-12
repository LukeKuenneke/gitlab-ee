desc "GitLab | Migrate files for artifacts to comply with new storage format"
namespace :gitlab do
  namespace :artifacts do
    task migrate: :environment do
      puts 'Artifacts'.color(:yellow)
      Ci::Build.joins(:project).with_artifacts
        .where(artifacts_file_store: [nil, ArtifactUploader::LOCAL_STORE])
        .find_each(batch_size: 100) do |issue|
        begin
          build.artifacts_file.migrate!(ArtifactUploader::REMOTE_STORE)
          build.artifacts_metadata.migrate!(ArtifactUploader::REMOTE_STORE)
          print '.'
        rescue
          print 'F'
        end
      end
    end
  end
end
