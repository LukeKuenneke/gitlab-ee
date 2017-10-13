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

      addToSlackLinkProfileSlackPath: {
        type: String,
        required: true,
        default: '',
      },
    },

    data() {
      return {
        popupOpen: false,
        selectedProject: this.projects.length ? this.projects[0] : {},
      };
    },

    computed: {
      gitlabLogoSvg() {
        return gl.utils.spriteIcon('gitlab-logo');
      },

      slackLogoSvg() {
        return gl.utils.spriteIcon('slack-logo');
      },

      horizontalArrowsSvg() {
        return gl.utils.spriteIcon('horizontal-arrows');
      },

      rightArrowSvg() {
        return gl.utils.spriteIcon('right-arrow');
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
          url: this.addToSlackLinkProfileSlackPath,
          data: {
            projectId: this.selectedProjectId,
          },
          dataType: 'json',
        })
        .done((response) => {
          console.log('response', response);
        })
        .fail(Flash('Unable to build slack link.'));
      },
    },
  };
</script>

<template>
  <div>
    <div class="title">
      <h1>GitLab for Slack</h1>
      <p>Track your GitLab projects with GitLab for Slack.</p>
    </div>

    <div class="logos">
      <img v-once :src="gitlabLogoSvg">
      <div v-once v-html="horizontalArrowsSvg"></div>
      <img v-once :src="slackLogoSvg">
    </div>

    <button type="button" @click="togglePopup">Add GitLab to Slack</button>

    <div class="popup" v-if="popupOpen">
      <div v-if="isSignedIn && hasProjects">
        <p>Select GitLab project to link with your Slack team</p>

        <select v-model="selectedProject">
          <option v-for="project in projects" :key="project.id" :value="project">{{ project.name }}</option>
        </select>

        <button type="button" @click="addToSlack">
          Add to Slack
        </button>
      </div>

      <p v-else-if="isSignedIn && !hasProjects">
        You don't have any projects available.
      </p>

      <p v-else>
        You have to <a v-once :href="signInPath">log in</a>
      </p>
    </div>

    <img class="gif" v-once :src="gitlabForSlackGif">

    <div class="example">
      <h3>How it works</h3>

      <div class="well">
        <code>/project-name issue show &lt;id&gt;</code>
        <div v-once v-html="rightArrowSvg"></div>
        Shows the issue with id &lt;id&gt;
      </div>

      <a href="#to-be-added">More Slack commands</a>
    </div>
  </div>
</template>
