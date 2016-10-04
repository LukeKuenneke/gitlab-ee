# == Schema Information
#
# Table name: remote_mirrors
#
#  id                         :integer          not null, primary key
#  project_id                 :integer
#  url                        :string
#  enabled                    :boolean          default(TRUE)
#  update_status              :string
#  last_update_at             :datetime
#  last_successful_update_at  :datetime
#  last_error                 :string
#  encrypted_credentials      :text
#  encrypted_credentials_iv   :string
#  encrypted_credentials_salt :string
#  created_at                 :datetime         not null
#  updated_at                 :datetime         not null
#

require 'rails_helper'

describe RemoteMirror do
  describe 'encrypting credentials' do
    context 'when setting URL for a first time' do
      it 'stores the URL without credentials' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(mirror.read_attribute(:url)).to eq('http://test.com')
      end

      it 'stores the credentials on a separate field' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(mirror.credentials).to eq({ user: 'foo', password: 'bar' })
      end

      it 'handles credentials with large content' do
        mirror = create_mirror(url: 'http://bxnhm8dote33ct932r3xavslj81wxmr7o8yux8do10oozckkif:9ne7fuvjn40qjt35dgt8v86q9m9g9essryxj76sumg2ccl2fg26c0krtz2gzfpyq4hf22h328uhq6npuiq6h53tpagtsj7vsrz75@test.com')

        expect(mirror.credentials).to eq({
          user: 'bxnhm8dote33ct932r3xavslj81wxmr7o8yux8do10oozckkif',
          password: '9ne7fuvjn40qjt35dgt8v86q9m9g9essryxj76sumg2ccl2fg26c0krtz2gzfpyq4hf22h328uhq6npuiq6h53tpagtsj7vsrz75'
        })
      end
    end

    context 'when updating the URL' do
      it 'allows a new URL without credentials' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        mirror.update_attribute(:url, 'http://test.com')

        expect(mirror.url).to eq('http://test.com')
        expect(mirror.credentials).to eq({ user: nil, password: nil })
      end

      it 'allows a new URL with credentials' do
        mirror = create_mirror(url: 'http://test.com')

        mirror.update_attribute(:url, 'http://foo:bar@test.com')

        expect(mirror.url).to eq('http://foo:bar@test.com')
        expect(mirror.credentials).to eq({ user: 'foo', password: 'bar' })
      end

      it 'updates the remote config if credentials changed' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')
        repo = mirror.project.repository

        mirror.update_attribute(:url, 'http://foo:baz@test.com')

        expect(repo.config["remote.#{mirror.ref_name}.url"]).to eq('http://foo:baz@test.com')
      end

      context 'URL same as import URL' do
        let(:mirror) { create_mirror(url: 'http://random.url') }
        let(:url) { 'http://foo:bar@test.com' }

        before do
          mirror.project.update(import_url: url)
          mirror.project.repository.add_remote(mirror.ref_name, url)
          mirror.update(url: url)
        end

        it 'updates the URL with no errors' do
          expect(mirror).to be_valid
        end

        it 'repo has only origin and one remote mirror' do
          expect(mirror.project.repository.raw_repository.remote_names).to match(['origin', mirror.ref_name])
        end
      end
    end
  end

  describe '#safe_url' do
    context 'when URL contains credentials' do
      it 'masks the credentials' do
        mirror = create_mirror(url: 'http://foo:bar@test.com')

        expect(mirror.safe_url).to eq('http://*****:*****@test.com')
      end
    end

    context 'when URL does not contain credentials' do
      it 'shows the full URL' do
        mirror = create_mirror(url: 'http://test.com')

        expect(mirror.safe_url).to eq('http://test.com')
      end
    end
  end

  context 'stuck mirrors' do
    it 'includes mirrors stuck in started with no last_update_at set' do
      mirror = create_mirror(url: 'http://cantbeblank',
                             update_status: 'started',
                             last_update_at: nil,
                             updated_at: 25.hours.ago)

      expect(RemoteMirror.stuck.last).to eq(mirror)
    end
  end

  def create_mirror(params)
    project = FactoryGirl.create(:project)
    project.remote_mirrors.create!(params)
  end
end
