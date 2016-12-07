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

  context 'no project' do
    it 'includes mirror with a project in pending_delete' do
      mirror = create_mirror(url: 'http://cantbeblank',
                             update_status: 'finished',
                             enabled: true,
                             last_update_at: nil,
                             updated_at: 25.hours.ago)
      project = mirror.project
      project.pending_delete = true
      project.save
      mirror.reload

      expect(mirror.sync).to be_nil
      expect(mirror.valid?).to be_truthy
      expect(mirror.update_status).to eq('finished')
    end
  end

  def create_mirror(params)
    project = FactoryGirl.create(:project)
    project.remote_mirrors.create!(params)
  end
end
