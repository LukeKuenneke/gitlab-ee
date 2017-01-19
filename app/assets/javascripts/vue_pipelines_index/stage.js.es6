/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign, no-bitwise */

((gl) => {
  gl.VueStage = Vue.extend({
    data() {
      return {
<<<<<<< HEAD
        count: 0,
=======
>>>>>>> gitlab-ce/8-16-stable
        builds: '',
        spinner: '<span class="fa fa-spinner fa-spin"></span>',
      };
    },
    props: ['stage', 'svgs', 'match'],
    methods: {
<<<<<<< HEAD
      fetchBuilds() {
        if (this.count > 0) return null;
        return this.$http.get(this.stage.dropdown_path)
          .then((response) => {
            this.count += 1;
=======
      fetchBuilds(e) {
        const areaExpanded = e.currentTarget.attributes['aria-expanded'];

        if (areaExpanded && (areaExpanded.textContent === 'true')) return null;

        return this.$http.get(this.stage.dropdown_path)
          .then((response) => {
>>>>>>> gitlab-ce/8-16-stable
            this.builds = JSON.parse(response.body).html;
          }, () => {
            const flash = new Flash('Something went wrong on our end.');
            return flash;
          });
      },
    },
    computed: {
      buildsOrSpinner() {
        return this.builds ? this.builds : this.spinner;
      },
      dropdownClass() {
        if (this.builds) return 'js-builds-dropdown-container';
        return 'js-builds-dropdown-loading builds-dropdown-loading';
      },
      buildStatus() {
        return `Build: ${this.stage.status.label}`;
      },
      tooltip() {
        return `has-tooltip ci-status-icon ci-status-icon-${this.stage.status.group}`;
      },
      svg() {
        const { icon } = this.stage.status;
        const stageIcon = icon.replace(/icon/i, 'stage_icon');
        return this.svgs[this.match(stageIcon)];
      },
      triggerButtonClass() {
        return `mini-pipeline-graph-dropdown-toggle has-tooltip js-builds-dropdown-button ci-status-icon-${this.stage.status.group}`;
      },
    },
    template: `
      <div>
        <button
<<<<<<< HEAD
          @click='fetchBuilds'
=======
          @click='fetchBuilds($event)'
>>>>>>> gitlab-ce/8-16-stable
          :class="triggerButtonClass"
          :title='stage.title'
          data-placement="top"
          data-toggle="dropdown"
          type="button"
        >
          <span v-html="svg"></span>
          <i class="fa fa-caret-down "></i>
        </button>
        <ul class="dropdown-menu mini-pipeline-graph-dropdown-menu js-builds-dropdown-container">
          <div class="arrow-up"></div>
          <div
            @click=''
            :class="dropdownClass"
            class="js-builds-dropdown-list scrollable-menu"
            v-html="buildsOrSpinner"
          >
          </div>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
