require 'rails_helper'

describe Projects::RelatedIssuesController, type: :controller do
  let(:user) { create :user }
  let(:project) { create(:project_empty_repo) }
  let(:issue) { create :issue, project: project }

  describe 'GET #index' do
    let(:service) { double(RelatedIssues::ListService, execute: service_response) }
    let(:service_response) { [{ 'foo' => 'bar' }] }

    before do
      project.team << [user, :guest]
      sign_in user

      allow(RelatedIssues::ListService).to receive(:new)
        .with(issue, user)
        .and_return(service)
    end

    subject do
      get :index, namespace_id: issue.project.namespace,
                  project_id: issue.project,
                  issue_id: issue,
                  format: :json
    end

    it 'returns JSON response' do
      is_expected.to have_http_status(200)
      expect(json_response).to eq(service_response)
    end
  end

  describe 'POST #create' do
    let(:service) { double(RelatedIssues::CreateService, execute: service_response) }
    let(:service_response) { { 'message' => 'yay' } }
    let(:issue_references) { double }
    let(:user_role) { :developer }

    before do
      project.team << [user, user_role]
      sign_in user

      allow(RelatedIssues::CreateService).to receive(:new)
        .with(issue, user, { issue_references: issue_references })
        .and_return(service)
    end

    subject do
      post :create, namespace_id: issue.project.namespace,
                    project_id: issue.project,
                    issue_id: issue,
                    issue_references: issue_references,
                    format: :json
    end

    context 'with success' do
      it 'returns success JSON' do
        is_expected.to have_http_status(200)
        expect(json_response).to eq(service_response)
      end
    end

    context 'with failure' do
      context 'when unauthorized' do
        let(:user_role) { :guest }

        it 'returns 404' do
          is_expected.to have_http_status(404)
        end
      end

      context 'when failure service result' do
        let(:service_response) { { 'http_status' => 401 } }

        it 'returns failure JSON' do
          is_expected.to have_http_status(401)
          expect(json_response).to eq(service_response)
        end
      end
    end
  end
end
