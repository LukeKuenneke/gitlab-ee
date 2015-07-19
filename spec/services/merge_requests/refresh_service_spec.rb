require 'spec_helper'

describe MergeRequests::RefreshService do
  let(:project) { create(:project) }
  let(:user) { create(:user) }
  let(:service) { MergeRequests::RefreshService }

  describe :execute do
    before do
      @user = create(:user)
      group = create(:group)
      group.add_owner(@user)

      @project = create(:project, namespace: group, approvals_before_merge: 1, reset_approvals_on_push: true)
      @fork_project = Projects::ForkService.new(@project, @user).execute
      @merge_request = create(:merge_request,
                              source_project: @project,
                              source_branch: 'master',
                              target_branch: 'feature',
                              target_project: @project)

      @fork_merge_request = create(:merge_request,
                                   source_project: @fork_project,
                                   source_branch: 'master',
                                   target_branch: 'feature',
                                   target_project: @project)

      @merge_request.approvals.create(user_id: user.id)
      @fork_merge_request.approvals.create(user_id: user.id)

      @commits = @merge_request.commits

      @oldrev = @commits.last.id
      @newrev = @commits.first.id
    end

    context 'push to origin repo source branch' do
      let(:refresh_service) { service.new(@project, @user) }
      before do
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it 'should execute hooks with update action' do
        expect(refresh_service).to have_received(:execute_hooks).
          with(@merge_request, 'update')
      end

      it { expect(@merge_request.notes).not_to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@merge_request.approvals).to be_empty }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@fork_merge_request.notes).to be_empty }
      it { expect(@fork_merge_request.approvals).to be_empty }
    end

    context 'push to origin repo target branch' do
      before do
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request).to be_merged }
      it { expect(@fork_merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
    end

    context 'push to fork repo source branch' do
      let(:refresh_service) { service.new(@fork_project, @user) }
      before do
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs
      end

      it 'should execute hooks with update action' do
        expect(refresh_service).to have_received(:execute_hooks).
          with(@fork_merge_request, 'update')
      end

      it { expect(@merge_request.notes).to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request.notes.last.note).to include('Added 4 commits') }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
    end

    context 'push to fork repo target branch' do
      before do
        service.new(@fork_project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes).to be_empty }
      it { expect(@merge_request).to be_open }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request.notes).to be_empty }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
    end

    context 'push to origin repo target branch after fork project was removed' do
      before do
        @fork_project.destroy
        service.new(@project, @user).execute(@oldrev, @newrev, 'refs/heads/feature')
        reload_mrs
      end

      it { expect(@merge_request.notes.last.note).to include('changed to merged') }
      it { expect(@merge_request).to be_merged }
      it { expect(@merge_request.approvals).not_to be_empty }
      it { expect(@fork_merge_request).to be_open }
      it { expect(@fork_merge_request.notes).to be_empty }
      it { expect(@fork_merge_request.approvals).not_to be_empty }
    end

    context 'resetting approvals if they are enabled' do
      it "does not reset approvals if approvals_before_merge si disabled" do
        @project.update(approvals_before_merge: 0)
        refresh_service = service.new(@project, @user)
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs

        expect(@merge_request.approvals).not_to be_empty
      end

      it "does not reset approvals if reset_approvals_on_push si disabled" do
        @project.update(reset_approvals_on_push: false)
        refresh_service = service.new(@project, @user)
        allow(refresh_service).to receive(:execute_hooks)
        refresh_service.execute(@oldrev, @newrev, 'refs/heads/master')
        reload_mrs

        expect(@merge_request.approvals).not_to be_empty
      end
    end

    def reload_mrs
      @merge_request.reload
      @fork_merge_request.reload
    end
  end
end
