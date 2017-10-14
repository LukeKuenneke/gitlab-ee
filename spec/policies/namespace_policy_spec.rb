require 'spec_helper'

describe NamespacePolicy do
  let(:user) { create(:user) }
  let(:owner) { create(:user) }
  let(:auditor) { create(:user, :auditor) }
  let(:admin) { create(:admin) }
  let(:namespace) { create(:namespace, owner: owner) }

  let(:owner_permissions) { [:create_projects, :admin_namespace] }

  let(:admin_permissions) { owner_permissions }

  subject { described_class.new(current_user, namespace) }

  context 'with no user' do
    let(:current_user) { nil }

    it { is_expected.to be_banned }
  end

  context 'regular user' do
    let(:current_user) { user }

    it { is_expected.to be_disallowed(*owner_permissions) }
  end

  context 'owner' do
    let(:current_user) { owner }

    it { is_expected.to be_allowed(*owner_permissions) }
  end

  context 'auditor' do
    let(:current_user) { auditor }

    context 'owner' do
      let(:namespace) { create(:namespace, owner: auditor) }

      it { is_expected.to be_allowed(*owner_permissions) }
    end

    context 'non-owner' do
      it { is_expected.to be_disallowed(*owner_permissions) }
    end
  end

  context 'admin' do
    let(:current_user) { admin }

    it { is_expected.to be_allowed(*owner_permissions) }
  end
  

  context "create projects" do
    let(:current_user) { create(:user) }
    let(:namespace) { current_user.namespace }

    subject { described_class.new(current_user, namespace) }

    context "user namespace" do
      it { is_expected.to be_allowed(:create_projects) }
    end

    context "user who has exceeded project limit" do
      let(:current_user) { create(:user, projects_limit: 0) }

      it { is_expected.not_to be_allowed(:create_projects) }
    end
  end
end
