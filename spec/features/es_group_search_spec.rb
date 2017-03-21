require 'spec_helper'

feature 'Group elastic search', js: true, feature: true do
  let(:user) { create(:user) }
  let(:group) { create(:group) }
  let(:project) { create(:project, namespace: group) }

  def choose_group(group)
    find('.js-search-group-dropdown').click
    wait_for_ajax

    page.within '.search-holder' do
      click_link group.name
    end
  end

  before do
    stub_application_setting(elasticsearch_search: true, elasticsearch_indexing: true)
    Gitlab::Elastic::Helper.create_empty_index

    project.team << [user, :master]
    group.add_owner(user)

    login_with(user)
  end

  after do
    Gitlab::Elastic::Helper.delete_index
    stub_application_setting(elasticsearch_search: false, elasticsearch_indexing: false)
  end

  describe 'issue search' do
    before do
      create(:issue, project: project, title: 'chosen issue title')

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds the issue' do
      visit search_path

      choose_group group
      fill_in 'search', with: 'chosen'
      click_button 'Search'

      select_filter('Issues')
      expect(page).to have_content('chosen issue title')
    end
  end

  describe 'blob search' do
    before do
      project.repository.index_blobs

      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds files' do
      visit search_path

      choose_group group
      fill_in 'search', with: 'def'
      click_button 'Search'

      select_filter('Code')

      expect(page).to have_selector('.file-content .code')
    end
  end

  describe 'commit search' do
    before do
      project.repository.index_commits
      Gitlab::Elastic::Helper.refresh_index
    end

    it 'finds commits' do
      visit search_path

      choose_group group
      fill_in 'search', with: 'add'
      click_button 'Search'

      select_filter('Commits')

      expect(page).to have_selector('.commit-list > .commit')
    end
  end
end
