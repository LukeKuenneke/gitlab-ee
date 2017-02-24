require 'spec_helper'

describe JenkinsDeprecatedService, caching: true do
  include ReactiveCachingHelpers

  describe "Associations" do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'commits methods' do
    def status_body_for_icon(state)
      <<eos
        <h1 class="build-caption page-headline"><img style="width: 48px; height: 48px; " alt="Success" class="icon-#{state} icon-xlg" src="/static/855d7c3c/images/48x48/#{state}" tooltip="Success" title="Success">
                Build #188
              (Oct 15, 2014 9:45:21 PM)
                    </h1>
eos
    end

    describe '#calculate_reactive_cache' do
      let(:pass_unstable) { '0' }
      before do
        @service = JenkinsDeprecatedService.new
        allow(@service).to receive_messages(
          service_hook: true,
          project_url: 'http://jenkins.gitlab.org/job/2',
          multiproject_enabled: '0',
          pass_unstable: pass_unstable,
          token: 'verySecret'
        )
      end

      statuses = { 'blue.png' => 'success', 'yellow.png' => 'failed', 'red.png' => 'failed', 'aborted.png' => 'failed', 'blue-anime.gif' => 'running', 'grey.png' => 'pending' }
      statuses.each do |icon, state|
        it "has a commit_status of #{state} when the icon #{icon} exists." do
          stub_request(:get, "http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c").to_return(status: 200, body: status_body_for_icon(icon), headers: {})

          expect(@service.calculate_reactive_cache('2ab7834c', 'master')).to eq(commit_status: state)
        end
      end

      context 'with passing unstable' do
        let(:pass_unstable) { '1' }

        it 'has a commit_status of success when the icon yellow exists' do
          stub_request(:get, "http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c").to_return(status: 200, body: status_body_for_icon('yellow.png'), headers: {})

          expect(@service.calculate_reactive_cache('2ab7834c', 'master')).to eq(commit_status: 'success')
        end
      end
    end

    describe '#commit_status' do
      subject(:service) { described_class.new(project_id: 666) }

      it 'returns the contents of the reactive cache' do
        stub_reactive_cache(service, { commit_status: 'foo' }, 'sha', 'ref')

        expect(service.commit_status('sha', 'ref')).to eq('foo')
      end
    end

    describe 'multiproject enabled' do
      let!(:project) { create(:project) }
      before do
        @service = JenkinsDeprecatedService.new
        allow(@service).to receive_messages(
          service_hook: true,
          project_url: 'http://jenkins.gitlab.org/job/2',
          multiproject_enabled: '1',
          token: 'verySecret',
          project: project
        )
      end

      describe :build_page do
        it { expect(@service.build_page("2ab7834c", 'master')).to eq("http://jenkins.gitlab.org/job/#{project.name}_master/scm/bySHA1/2ab7834c") }
      end

      describe :build_page_with_branch do
        it { expect(@service.build_page("2ab7834c", 'test_branch')).to eq("http://jenkins.gitlab.org/job/#{project.name}_test_branch/scm/bySHA1/2ab7834c") }
      end
    end

    describe 'multiproject disabled' do
      before do
        @service = JenkinsDeprecatedService.new
        allow(@service).to receive_messages(
          service_hook: true,
          project_url: 'http://jenkins.gitlab.org/job/2',
          multiproject_enabled: '0',
          token: 'verySecret'
        )
      end

      describe :build_page do
        it { expect(@service.build_page("2ab7834c", 'master')).to eq("http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c") }
      end

      describe :build_page_with_branch do
        it { expect(@service.build_page("2ab7834c", 'test_branch')).to eq("http://jenkins.gitlab.org/job/2/scm/bySHA1/2ab7834c") }
      end
    end
  end
end
