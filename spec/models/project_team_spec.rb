require "spec_helper"

describe ProjectTeam do
  let(:master) { create(:user) }
  let(:reporter) { create(:user) }
  let(:guest) { create(:user) }
  let(:nonmember) { create(:user) }

  context 'personal project' do
    let(:project) { create(:empty_project) }

    before do
      project.team << [master, :master]
      project.team << [reporter, :reporter]
      project.team << [guest, :guest]
    end

    describe 'members collection' do
      it { project.team.masters.should include(master) }
      it { project.team.masters.should_not include(guest) }
      it { project.team.masters.should_not include(reporter) }
      it { project.team.masters.should_not include(nonmember) }
    end

    describe 'access methods' do
      it { project.team.master?(master).should be_true }
      it { project.team.master?(guest).should be_false }
      it { project.team.master?(reporter).should be_false }
      it { project.team.master?(nonmember).should be_false }
    end
  end

  context 'group project' do
    let(:group) { create(:group) }
    let(:project) { create(:empty_project, group: group) }

    before do
      group.add_user(master, Gitlab::Access::MASTER)
      group.add_user(reporter, Gitlab::Access::REPORTER)
      group.add_user(guest, Gitlab::Access::GUEST)

      # If user is a group and a project member - GitLab uses highest permission
      # So we add group guest as master and add group master as guest
      # to this project to test highest access
      project.team << [guest, :master]
      project.team << [master, :guest]
    end

    describe 'members collection' do
      it { project.team.reporters.should include(reporter) }
      it { project.team.masters.should include(master) }
      it { project.team.masters.should include(guest) }
      it { project.team.masters.should_not include(reporter) }
      it { project.team.masters.should_not include(nonmember) }
    end

    describe 'access methods' do
      it { project.team.reporter?(reporter).should be_true }
      it { project.team.master?(master).should be_true }
      it { project.team.master?(guest).should be_true }
      it { project.team.master?(reporter).should be_false }
      it { project.team.master?(nonmember).should be_false }
    end
  end

  describe :max_invited_level do
    let(:group) { create(:group) }
    let(:project) { create(:empty_project) }

    before do
      group_link = project.project_group_links.new
      group_link.group = group
      group_link.group_access = Gitlab::Access::DEVELOPER
      group_link.save

      group.add_user(master, Gitlab::Access::MASTER)
      group.add_user(reporter, Gitlab::Access::REPORTER)
    end

    it { project.team.max_invited_level(master.id).should == Gitlab::Access::DEVELOPER }
    it { project.team.max_invited_level(reporter.id).should == Gitlab::Access::REPORTER }
    it { project.team.max_invited_level(nonmember.id).should be_nil }
  end
end
