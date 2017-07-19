require 'spec_helper'

describe Projects::MirrorsController do
  let(:sync_times) { Gitlab::Mirror::SYNC_TIME_OPTIONS.values }

  describe 'setting up a mirror' do
    context 'when the current project is a mirror' do
      before do
        @project = create(:project, :mirror)
        sign_in(@project.owner)
      end

      context 'sync_time update' do
        it 'allows sync_time update with valid time' do
          sync_times.each do |sync_time|
            expect do
              do_put(@project, sync_time: sync_time)
            end.to change { Project.mirror.where(sync_time: sync_time).count }.by(1)
          end
        end

        it 'fails to update sync_time with invalid time' do
          expect do
            do_put(@project, sync_time: 1000)
          end.not_to change { @project.sync_time }
        end
      end
    end
  end

  describe 'setting up a remote mirror' do
    context 'when the current project is a mirror' do
      before do
        @project = create(:project, :mirror)
        sign_in(@project.owner)
      end

      it 'allows to create a remote mirror' do
        expect do
          do_put(@project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com' } })
        end.to change { RemoteMirror.count }.to(1)
      end

      context 'sync_time update' do
        it 'allows sync_time update with valid time' do
          sync_times.each do |sync_time|
            expect do
              do_put(@project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com', 'sync_time' => sync_time } })
            end.to change { RemoteMirror.where(sync_time: sync_time).count }.by(1)
          end
        end

        it 'fails to update sync_time with invalid time' do
          expect(@project.remote_mirrors.count).to eq(0)

          expect do
            do_put(@project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com', 'sync_time' => 1000 } })
          end.not_to change { @project.remote_mirrors.count }
        end
      end

      context 'when remote mirror has the same URL' do
        it 'does not allow to create the remote mirror' do
          expect do
            do_put(@project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => @project.import_url } })
          end.not_to change { RemoteMirror.count }
        end

        context 'with disabled local mirror' do
          it 'allows to create a remote mirror' do
            expect do
              do_put(@project, mirror: 0, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => @project.import_url } })
            end.to change { RemoteMirror.count }.to(1)
          end
        end
      end
    end

    context 'when the current project is not a mirror' do
      it 'allows to create a remote mirror' do
        project = create(:project)
        sign_in(project.owner)

        expect do
          do_put(project, remote_mirrors_attributes: { '0' => { 'enabled' => 1, 'url' => 'http://foo.com' } })
        end.to change { RemoteMirror.count }.to(1)
      end
    end

    context 'when the current project has a remote mirror' do
      before do
        @project = create(:project)
        @remote_mirror = @project.remote_mirrors.create!(enabled: 1, url: 'http://local.dev')
        sign_in(@project.owner)
      end

      context 'when trying to create a mirror with the same URL' do
        it 'should not setup the mirror' do
          do_put(@project, mirror: true, import_url: @remote_mirror.url)

          expect(@project.reload.mirror).to be_falsey
          expect(@project.reload.import_url).to be_blank
        end
      end

      context 'when trying to create a mirror with a different URL' do
        it 'should setup the mirror' do
          do_put(@project, mirror: true, mirror_user_id: @project.owner.id, import_url: 'http://test.com')

          expect(@project.reload.mirror).to eq(true)
          expect(@project.reload.import_url).to eq('http://test.com')
        end

        context 'mirror user is not the current user' do
          it 'should only assign the current user' do
            new_user = create(:user)
            @project.add_master(new_user)

            do_put(@project, mirror: true, mirror_user_id: new_user.id, import_url: 'http://local.dev')

            expect(@project.reload.mirror).to eq(true)
            expect(@project.reload.mirror_user.id).to eq(@project.owner.id)
          end
        end
      end
    end
  end

  def do_put(project, options)
    attrs = { namespace_id: project.namespace.to_param, project_id: project.to_param }
    attrs[:project] = options

    put :update, attrs
  end
end
