require 'spec_helper'

describe EE::User, models: true do
  describe '#access_level=' do
    let(:user) { build(:user) }

    before do
      # `auditor?` returns true only when the user is an auditor _and_ the auditor license
      # add-on is present. We aren't testing this here, so we can assume that the add-on exists.
      allow_any_instance_of(License).to receive(:feature_available?).with(:auditor_user) { true }
    end

    it "does not set 'auditor' for an invalid access level" do
      user.access_level = :invalid_access_level

      expect(user.auditor).to be false
    end

    it "does not set 'auditor' for admin level" do
      user.access_level = :admin

      expect(user.auditor).to be false
    end

    it "assigns the 'auditor' access level" do
      user.access_level = :auditor

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end

    it "assigns the 'auditor' access level" do
      user.access_level = :regular

      expect(user.access_level).to eq(:regular)
      expect(user.admin).to be false
      expect(user.auditor).to be false
    end

    it "clears the 'admin' access level when a user is made an auditor" do
      user.access_level = :admin
      user.access_level = :auditor

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end

    it "clears the 'auditor' access level when a user is made an admin" do
      user.access_level = :auditor
      user.access_level = :admin

      expect(user.access_level).to eq(:admin)
      expect(user.admin).to be true
      expect(user.auditor).to be false
    end

    it "doesn't clear existing 'auditor' access levels when an invalid access level is passed in" do
      user.access_level = :auditor
      user.access_level = :invalid_access_level

      expect(user.access_level).to eq(:auditor)
      expect(user.admin).to be false
      expect(user.auditor).to be true
    end
  end

  describe '#has_full_private_access?' do
    it 'returns true for auditor user' do
      user = build(:user, :auditor)

      expect(user.has_full_private_access?).to be_truthy
    end
  end
end
