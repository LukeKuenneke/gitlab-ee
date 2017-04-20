require 'spec_helper'

describe ExpirePipelineCacheWorker do
  let(:user) { create(:user) }
  let(:project) { create(:empty_project) }
  let(:pipeline) { create(:ci_pipeline, project: project) }
  subject { described_class.new }

  describe '#perform' do
    it 'invalidates Etag caching for project pipelines path' do
      pipelines_path = "/#{project.full_path}/pipelines.json"
      new_mr_pipelines_path = "/#{project.full_path}/merge_requests/new.json"

      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(pipelines_path)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(new_mr_pipelines_path)

      subject.perform(pipeline.id)
    end

    it 'invalidates Etag caching for merge request pipelines if pipeline runs on any commit of that source branch' do
      project = create(:project, :repository)
      pipeline = create(:ci_empty_pipeline, status: 'created', project: project, ref: 'master', sha: project.repository.commit('master^').id)
      merge_request = create(:merge_request, source_project: project, source_branch: pipeline.ref)
      merge_request_pipelines_path = "/#{project.full_path}/merge_requests/#{merge_request.iid}/pipelines.json"

      allow_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch)
      expect_any_instance_of(Gitlab::EtagCaching::Store).to receive(:touch).with(merge_request_pipelines_path)

      subject.perform(pipeline.id)
    end

    it 'updates the cached status for a project' do
      expect(Gitlab::Cache::Ci::ProjectPipelineStatus).to receive(:update_for_pipeline).
                                                            with(pipeline)

      subject.perform(pipeline.id)
    end
  end
end
