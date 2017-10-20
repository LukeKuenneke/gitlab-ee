<script>
  import Flash from '~/flash';

  export default {
    props: {
      projects: {
        type: Array,
        required: true,
        default: [],
      },

      isSignedIn: {
        type: Boolean,
        required: true,
        default: false,
      },

      gitlabForSlackGif: {
        type: String,
        required: true,
        default: '',
      },

      signInPath: {
        type: String,
        required: true,
        default: '',
      },

      slackLinkProfileSlackPath: {
        type: String,
        required: true,
        default: '',
      },
    },

    data() {
      return {
        popupOpen: false,
        selectedProjectId: this.projects.length ? this.projects[0].id : 0,
      };
    },

    computed: {
      gitlabLogoSvg() {
        return gl.utils.spriteIcon('gitlab-logo');
      },

      slackLogoSvg() {
        return gl.utils.spriteIcon('slack-logo');
      },

      doubleHeadedArrowSvg() {
        return gl.utils.spriteIcon('double-headed-arrow');
      },

      arrowRightSvg() {
        return gl.utils.spriteIcon('arrow-right');
      },

      hasProjects() {
        return !!this.projects.length;
      },
    },

    methods: {
      togglePopup() {
        this.popupOpen = !this.popupOpen;
      },

      addToSlack() {
        $.ajax({
          url: this.slackLinkProfileSlackPath,
          data: {
            project_id: this.selectedProjectId,
          },
          dataType: 'json',
        })
        .done(response => window.location.assign(response.add_to_slack_link))
        .fail(() => Flash('Unable to build slack link.'));
      },
    },
  };
</script>

<template>
  <div class="add-gitlab-slack-application">
    <div class="title">
      <h1>GitLab for Slack</h1>
      <p>Track your GitLab projects with GitLab for Slack.</p>
    </div>

    <div class="logos">
      <img v-once :src="gitlabLogoSvg">
      <div v-once v-html="doubleHeadedArrowSvg"></div>
      <img v-once :src="slackLogoSvg">
    </div>

    <button type="button" class="btn btn-red popup-button" @click="togglePopup">Add GitLab to Slack</button>

    <div class="popup" v-if="popupOpen">
      <div class="select-container" v-if="isSignedIn && hasProjects">
        <strong>Select GitLab project to link with your Slack team</strong>

        <select class="project-select" v-model="selectedProjectId">
          <option v-for="project in projects" :key="project.id" :value="project.id">{{ project.name }}</option>
        </select>

        <button type="button" class="add-to-slack-button btn btn-red" @click="addToSlack">
          Add to Slack
        </button>
      </div>

      <span class="text" v-else-if="isSignedIn && !hasProjects">
        You don't have any projects available.
      </span>

      <span class="text" v-else>
        You have to <a v-once :href="signInPath">log in</a>
      </span>
    </div>

    <img class="gif" v-once :src="gitlabForSlackGif">

    <div class="example">
      <h3>How it works</h3>

      <div class="well">
        <code>/project-name issue show &lt;id&gt;</code>
        <div v-once v-html="arrowRightSvg"></div>
        Shows the issue with id &lt;id&gt;
      </div>

      <a href="#to-be-added">More Slack commands</a>
    </div>
  </div>
</template>
