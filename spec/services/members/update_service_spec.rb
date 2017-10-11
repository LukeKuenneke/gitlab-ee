require 'spec_helper'

describe Members::UpdateService do
  let(:current_user) { create(:user) }
  let(:member_user) { create(:user) }
  let(:project) { create(:project, :public) }
  let(:group) { create(:group, :public) }
  let(:permission) { :update }

  shared_examples 'a service raising ActiveRecord::RecordNotFound' do
    it 'raises ActiveRecord::RecordNotFound' do
      expect { described_class.new(source, current_user, params).execute(permission: permission) }
        .to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  shared_examples 'a service raising Gitlab::Access::AccessDeniedError' do
    it 'raises Gitlab::Access::AccessDeniedError' do
      expect { described_class.new(source, current_user, params).execute(permission: permission) }
        .to raise_error(Gitlab::Access::AccessDeniedError)
    end
  end

  shared_examples 'a service updating a member' do
    it 'updates the member' do
      member = source.members.find_by!(user_id: member_user.id)
      result = described_class.new(source, current_user, params).execute(permission: permission)

      expect(result[:status]).to eq(:success)
      expect(member.reload.access_level).to eq(Gitlab::Access::MASTER)
    end

    context 'when given an :id' do
      let(:params) do
        {
          id: source.members.find_by!(user_id: member_user.id).id,
          access_level: Gitlab::Access::MASTER
        }
      end

      it 'updates the member' do
        member = source.members.find_by!(user_id: member_user.id)
        result = described_class.new(source, current_user, params).execute(permission: permission)

        expect(result[:status]).to eq(:success)
        expect(member.reload.access_level).to eq(Gitlab::Access::MASTER)
      end
    end
  end

  context 'when no member is found' do
    let(:params) { { user_id: 42, access_level: Gitlab::Access::MASTER } }

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { project }
    end

    it_behaves_like 'a service raising ActiveRecord::RecordNotFound' do
      let(:source) { group }
    end
  end

  context 'when a member is found' do
    before do
      project.team << [member_user, :developer]
      group.add_developer(member_user)
    end
    let(:params) do
      { user_id: member_user.id, access_level: Gitlab::Access::MASTER }
    end

    context 'when current user cannot update the given member' do
      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { project }
      end

      it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
        let(:source) { group }
      end
    end

    context 'when current user can update the given member' do
      before do
        project.team << [current_user, :master]
        group.add_owner(current_user)
      end

      it_behaves_like 'a service updating a member' do
        let(:source) { project }
      end

      it_behaves_like 'a service updating a member' do
        let(:source) { group }
      end
    end

    context 'when permission required is :override' do
      let(:permission) { :override }

      context 'when current user cannot update the given member' do
        it_behaves_like 'a service raising Gitlab::Access::AccessDeniedError' do
          let(:source) { group }
        end
      end

      context 'when current user can update the given member' do
        let(:current_user) { create(:admin) }
        before do
          allow(group).to receive(:ldap_synced?).and_return(true)
        end

        it_behaves_like 'a service updating a member' do
          let(:source) { group }
        end
      end
    end
  end
end
