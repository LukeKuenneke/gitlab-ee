require 'spec_helper'

describe GeoNode, type: :model do
  using RSpec::Parameterized::TableSyntax
  include ::EE::GeoHelpers

  let(:new_node) { create(:geo_node, schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }
  let(:new_primary_node) { create(:geo_node, :primary, schema: 'https', host: 'localhost', port: 3000, relative_url_root: 'gitlab') }
  let(:empty_node) { described_class.new }
  let(:primary_node) { create(:geo_node, :primary) }
  let(:node) { create(:geo_node) }

  let(:dummy_url) { 'https://localhost:3000/gitlab' }
  let(:url_helpers) { Gitlab::Routing.url_helpers }
  let(:api_version) { API::API.version }

  context 'associations' do
    it { is_expected.to belong_to(:geo_node_key).dependent(:destroy) }
    it { is_expected.to belong_to(:oauth_application).dependent(:destroy) }

    it { is_expected.to have_many(:geo_node_namespace_links) }
    it { is_expected.to have_many(:namespaces).through(:geo_node_namespace_links) }
  end

  context 'validations' do
    it { expect(new_node).to validate_presence_of(:geo_node_key) }
    it { expect(new_primary_node).not_to validate_presence_of(:geo_node_key) }
  end

  context 'default values' do
    let(:gitlab_host) { 'gitlabhost' }

    where(:attribute, :value) do
      :schema             | 'http'
      :host               | 'gitlabhost'
      :port               | 80
      :relative_url_root  | ''
      :primary            | false
      :repos_max_capacity | 25
      :files_max_capacity | 10
    end

    with_them do
      before do
        allow(Gitlab.config.gitlab).to receive(:host) { gitlab_host }
      end

      it { expect(empty_node[attribute]).to eq(value) }
    end
  end

  context 'prevent locking yourself out' do
    it 'does not accept adding a non primary node with same details as current_node' do
      node = GeoNode.new(
        host: Gitlab.config.gitlab.host,
        port: Gitlab.config.gitlab.port,
        relative_url_root: Gitlab.config.gitlab.relative_url_root,
        geo_node_key: build(:geo_node_key)
      )

      expect(node).not_to be_valid
      expect(node.errors.full_messages.count).to eq(1)
      expect(node.errors[:base].first).to match('locking yourself out')
    end
  end

  context 'dependent models and attributes for GeoNode' do
    let(:geo_node_key_attributes) { FactoryGirl.build(:geo_node_key).attributes }

    context 'on initialize' do
      it 'initializes a corresponding key' do
        expect(new_node.geo_node_key).to be_present
      end

      it 'is valid when required attributes are present' do
        new_node.geo_node_key_attributes = geo_node_key_attributes
        expect(new_node).to be_valid
      end
    end

    context 'on create' do
      it 'saves a corresponding key' do
        expect(node.geo_node_key).to be_persisted
      end

      it 'saves a corresponding oauth application if it is a secondary node' do
        expect(node.oauth_application).to be_persisted
      end

      context 'when is a primary node' do
        it 'has no oauth_application' do
          expect(primary_node.oauth_application).not_to be_present
        end

        it 'persists current clone_url_prefix' do
          expect(primary_node.clone_url_prefix).to be_present
        end
      end
    end
  end

  context 'cache expiration' do
    let(:new_node) { FactoryGirl.build(:geo_node) }

    it 'expires cache when saved' do
      expect(new_node).to receive(:expire_cache!).at_least(:once)

      new_node.save!
    end

    it 'expires cache when removed' do
      expect(node).to receive(:expire_cache!) # 1 for creation 1 for deletion

      node.destroy
    end
  end

  describe '#current?' do
    subject { described_class.new }

    it 'returns true when node is the current node' do
      stub_current_geo_node(subject)

      expect(subject.current?).to eq true
    end

    it 'returns false when node is not the current node' do
      stub_current_geo_node(double)

      expect(subject.current?).to eq false
    end
  end

  describe '#uri' do
    context 'when all fields are filled' do
      it 'returns an URI object' do
        expect(new_node.uri).to be_a URI
      end

      it 'includes schema home port and relative_url' do
        expected_uri = URI.parse(dummy_url)
        expect(new_node.uri).to eq(expected_uri)
      end
    end

    context 'when required fields are not filled' do
      it 'returns an initialized Geo node key' do
        expect(empty_node.geo_node_key).not_to be_nil
      end

      it 'returns an URI object' do
        expect(empty_node.uri).to be_a URI
      end
    end
  end

  describe '#url' do
    it 'returns a string' do
      expect(new_node.url).to be_a String
    end

    it 'includes schema home port and relative_url' do
      expected_url = 'https://localhost:3000/gitlab'
      expect(new_node.url).to eq(expected_url)
    end

    it 'defaults to existing HTTPS and relative URL if present' do
      stub_config_setting(port: 443)
      stub_config_setting(protocol: 'https')
      stub_config_setting(relative_url_root: '/gitlab')
      node = GeoNode.new

      expect(node.url).to eq('https://localhost/gitlab')
    end
  end

  describe '#url=' do
    subject { GeoNode.new }

    before do
      subject.url = dummy_url
    end

    it 'sets schema field based on url' do
      expect(subject.schema).to eq('https')
    end

    it 'sets host field based on url' do
      expect(subject.host).to eq('localhost')
    end

    it 'sets port field based on specified by url' do
      expect(subject.port).to eq(3000)
    end

    context 'when unspecified ports' do
      let(:dummy_http) { 'http://example.com/' }
      let(:dummy_https) { 'https://example.com/' }

      it 'sets port 80 when http and no port is specified' do
        subject.url = dummy_http
        expect(subject.port).to eq(80)
      end

      it 'sets port 443 when https and no port is specified' do
        subject.url = dummy_https
        expect(subject.port).to eq(443)
      end
    end
  end

  describe '#geo_transfers_url' do
    let(:transfers_url) { "https://localhost:3000/gitlab/api/#{api_version}/geo/transfers/lfs/1" }

    it 'returns api url based on node uri' do
      expect(new_node.geo_transfers_url(:lfs, 1)).to eq(transfers_url)
    end
  end

  describe '#geo_status_url' do
    let(:status_url) { "https://localhost:3000/gitlab/api/#{api_version}/geo/status" }

    it 'returns api url based on node uri' do
      expect(new_node.status_url).to eq(status_url)
    end
  end

  describe '#oauth_callback_url' do
    let(:oauth_callback_url) { 'https://localhost:3000/gitlab/oauth/geo/callback' }

    it 'returns oauth callback url based on node uri' do
      expect(new_node.oauth_callback_url).to eq(oauth_callback_url)
    end

    it 'returns url that matches rails url_helpers generated one' do
      route = url_helpers.oauth_geo_callback_url(protocol: 'https:', host: 'localhost', port: 3000, script_name: '/gitlab')
      expect(new_node.oauth_callback_url).to eq(route)
    end
  end

  describe '#oauth_logout_url' do
    let(:fake_state) { URI.encode('fakestate') }
    let(:oauth_logout_url) { "https://localhost:3000/gitlab/oauth/geo/logout?state=#{fake_state}" }

    it 'returns oauth logout url based on node uri' do
      expect(new_node.oauth_logout_url(fake_state)).to eq(oauth_logout_url)
    end

    it 'returns url that matches rails url_helpers generated one' do
      route = url_helpers.oauth_geo_logout_url(protocol: 'https:', host: 'localhost', port: 3000, script_name: '/gitlab', state: fake_state)
      expect(new_node.oauth_logout_url(fake_state)).to eq(route)
    end
  end

  describe '#missing_oauth_application?' do
    context 'on a primary node' do
      it 'returns false' do
        expect(primary_node).not_to be_missing_oauth_application
      end
    end

    it 'returns false when present' do
      expect(node).not_to be_missing_oauth_application
    end

    it 'returns true when it is not present' do
      node.oauth_application.destroy!
      node.reload
      expect(node).to be_missing_oauth_application
    end
  end

  describe '#projects_include?' do
    let(:unsynced_project) { create(:project) }

    it 'returns true without namespace restrictions' do
      expect(node.projects_include?(unsynced_project.id)).to eq true
    end

    context 'with namespace restrictions' do
      let(:synced_group) { create(:group) }

      before do
        node.update_attribute(:namespaces, [synced_group])
      end

      it 'returns true when project belongs to one of the namespaces' do
        project_in_synced_group = create(:project, group: synced_group)

        expect(node.projects_include?(project_in_synced_group.id)).to eq true
      end

      it 'returns false when project does not belong to one of the namespaces' do
        expect(node.projects_include?(unsynced_project.id)).to eq false
      end
    end
  end

  describe '#restricted_project_ids' do
    context 'without namespace restriction' do
      it 'returns nil' do
        expect(node.restricted_project_ids).to be_nil
      end
    end

    context 'with namespace restrictions' do
      it 'returns an array with unique project ids that belong to the namespaces' do
        group_1 = create(:group)
        group_2 = create(:group)
        nested_group_1 = create(:group, parent: group_1)
        project_1 = create(:project, group: group_1)
        project_2 = create(:project, group: nested_group_1)
        project_3 = create(:project, group: group_2)

        node.update_attribute(:namespaces, [group_1, group_2, nested_group_1])

        expect(node.restricted_project_ids).to match_array([project_1.id, project_2.id, project_3.id])
      end
    end
  end

  describe '#geo_node_key' do
    context 'primary node' do
      it 'cannot be set' do
        node = new_primary_node

        expect(node.geo_node_key).to be_nil

        node.geo_node_key = build(:geo_node_key)
        expect(node).to be_valid

        node.save!

        expect(node.geo_node_key(true)).to be_nil
      end
    end

    context 'secondary node' do
      it 'is automatically set' do
        node = build(:geo_node, url: 'http://example.com/')

        expect(node.geo_node_key).to be_present
        expect(node.geo_node_key.title).not_to include('example.com')

        node.save!

        expect(node.geo_node_key.title).to eq('Geo node: http://example.com/')
      end
    end
  end
end
