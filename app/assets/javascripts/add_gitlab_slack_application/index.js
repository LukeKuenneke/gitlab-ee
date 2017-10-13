import Vue from 'vue';
import AddGitlabSlackApplication from './components/add_gitlab_slack_application.vue';
import Translate from '../vue_shared/translate';

Vue.use(Translate);

function mountAddGitlabSlackApplication() {
  const el = document.getElementById('js-add-gitlab-slack-application-entry-point');

  if (!el) return;

  const dataNode = document.getElementById('js-add-gitlab-slack-application-entry-data');
  const initialData = JSON.parse(dataNode.innerHTML);

  const AddGitlabSlackApplicationComp = Vue.extend(AddGitlabSlackApplication);

  new AddGitlabSlackApplicationComp({
    propsData: {
      projects: initialData.projects || [],
      isSignedIn: initialData.is_signed_in,
      gitlabForSlackGIF: initialData.gitlab_for_slack_gif,
      signInPath: initialData.sign_in_path,
      addToSlackLinkProfileSlackPath: initialData.add_to_slack_link_profile_slack_path,
    },
  }).$mount(el);
}

document.addEventListener('DOMContentLoaded', mountAddGitlabSlackApplication);

export default mountAddGitlabSlackApplication;
