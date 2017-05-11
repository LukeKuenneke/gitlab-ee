require 'spec_helper'

describe 'Service Desk Setting', js: true, feature: true do
  include WaitForVueResource

  let(:project) { create(:project_empty_repo, :private) }
  let(:user) { create(:user) }

  before do
    project.add_master(user)
    login_as(user)
    allow_any_instance_of(License).to receive(:add_on?).and_call_original
    allow_any_instance_of(License).to receive(:add_on?).with('GitLab_ServiceDesk') { true }
    allow(::Gitlab::IncomingEmail).to receive(:enabled?) { true }
    allow(::Gitlab::IncomingEmail).to receive(:supports_wildcard?) { true }

    visit edit_namespace_project_path(project.namespace, project)
  end

  it 'shows activation checkbox' do
    expect(page).to have_selector("#service-desk-enabled-checkbox")
  end

  it 'shows incoming email after activating' do
    find("#service-desk-enabled-checkbox").click
    wait_for_vue_resource
    expect(find('.js-service-desk-setting-wrapper .panel-body')).to have_content(project.service_desk_address)
  end
end
