require 'spec_helper'

describe PushRule do
  let(:global_push_rule) { create(:push_rule_sample) }
  let(:push_rule) { create(:push_rule) }
  let(:user) { create(:user) }
  let(:project) { Projects::CreateService.new(user, { name: 'test', namespace: user.namespace }).execute }

  describe "Associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_numericality_of(:max_file_size).is_greater_than_or_equal_to(0).only_integer }
  end

  describe '#commit_validation?' do
    let(:settings_with_global_default) { %i(reject_unsigned_commits) }

    settings = {
      commit_message_regex: 'regex',
      branch_name_regex: 'regex',
      author_email_regex: 'regex',
      file_name_regex: 'regex',
      reject_unsigned_commits: true,
      member_check: true,
      prevent_secrets: true,
      max_file_size: 1
    }

    settings.each do |setting, value|
      context "when #{setting} is enabled at global level" do
        before do
          global_push_rule.update_column(setting, value)
        end

        it "returns true at project level" do
          rule = project.push_rule

          if settings_with_global_default.include?(setting)
            rule.update_column(setting, nil)
          end

          expect(rule.commit_validation?).to eq(true)
        end
      end
    end
  end

  describe '#commit_signature_allowed?' do
    let!(:premium_license) { create(:license, plan: License::PREMIUM_PLAN) }
    let(:signed_commit) { double(has_signature?: true) }
    let(:unsigned_commit) { double(has_signature?: false) }

    context 'when feature is not licensed and it is enabled' do
      before do
        stub_licensed_features(reject_unsigned_commits: false)
        global_push_rule.update_attribute(:reject_unsigned_commits, true)
      end

      it 'accepts unsigned commits' do
        expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(true)
      end
    end

    context 'when enabled at a global level' do
      before do
        global_push_rule.update_attribute(:reject_unsigned_commits, true)
      end

      it 'returns false if commit is not signed' do
        expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
      end

      context 'and disabled at a Project level' do
        it 'returns true if commit is not signed' do
          push_rule.update_attribute(:reject_unsigned_commits, false)

          expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(true)
        end
      end

      context 'and unset at a Project level' do
        it 'returns false if commit is not signed' do
          push_rule.update_attribute(:reject_unsigned_commits, nil)

          expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
        end
      end
    end

    context 'when disabled at a global level' do
      before do
        global_push_rule.update_attribute(:reject_unsigned_commits, false)
      end

      it 'returns true if commit is not signed' do
        expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(true)
      end

      context 'but enabled at a Project level' do
        before do
          push_rule.update_attribute(:reject_unsigned_commits, true)
        end

        it 'returns false if commit is not signed' do
          expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
        end

        it 'returns true if commit is signed' do
          expect(push_rule.commit_signature_allowed?(signed_commit)).to eq(true)
        end
      end

      context 'when user has enabled and disabled it at a project level' do
        before do
          # Let's test with the same boolean values that are sent through the form
          push_rule.update_attribute(:reject_unsigned_commits, '1')
          push_rule.update_attribute(:reject_unsigned_commits, '0')
        end

        context 'and it is enabled globally' do
          before do
            global_push_rule.update_attribute(:reject_unsigned_commits, true)
          end

          it 'returns false if commit is not signed' do
            expect(push_rule.commit_signature_allowed?(unsigned_commit)).to eq(false)
          end

          it 'returns true if commit is signed' do
            expect(push_rule.commit_signature_allowed?(signed_commit)).to eq(true)
          end
        end
      end
    end
  end

  describe '#available?' do
    shared_examples 'an unavailable push_rule' do
      it 'is not available' do
        expect(push_rule.available?(:reject_unsigned_commits)).to eq(false)
      end
    end

    shared_examples 'an available push_rule' do
      it 'is available' do
        expect(push_rule.available?(:reject_unsigned_commits)).to eq(true)
      end
    end

    describe 'reject_unsigned_commits' do
      context 'with the global push_rule' do
        let(:push_rule) { create(:push_rule_sample) }

        context 'with a EE starter license' do
          let!(:license) { create(:license, plan: License::STARTER_PLAN) }

          it_behaves_like 'an unavailable push_rule'
        end

        context 'with a EE premium license' do
          let!(:license) { create(:license, plan: License::PREMIUM_PLAN) }

          it_behaves_like 'an available push_rule'
        end
      end

      context 'with GL.com plans' do
        let(:group) { create(:group, plan: Plan.find_by!(name: gl_plan)) }
        let(:project) { create(:project, namespace: group) }
        let(:push_rule) { create(:push_rule, project: project) }

        before do
          create(:license, plan: License::PREMIUM_PLAN)
          stub_application_setting(check_namespace_plan: true)
        end

        context 'with a Bronze plan' do
          let(:gl_plan) { ::EE::Namespace::BRONZE_PLAN }

          it_behaves_like 'an unavailable push_rule'
        end

        context 'with a Silver plan' do
          let(:gl_plan) { ::EE::Namespace::SILVER_PLAN }

          it_behaves_like 'an available push_rule'
        end

        context 'with a Gold plan' do
          let(:gl_plan) { ::EE::Namespace::GOLD_PLAN }

          it_behaves_like 'an available push_rule'
        end
      end
    end
  end
end
