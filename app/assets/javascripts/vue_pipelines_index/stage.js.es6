/* global Vue, Flash, gl */
/* eslint-disable no-param-reassign */
import canceledSvg from '../../../views/shared/icons/_icon_status_canceled_borderless.svg';
import createdSvg from '../../../views/shared/icons/_icon_status_created_borderless.svg';
import failedSvg from '../../../views/shared/icons/_icon_status_failed_borderless.svg';
import manualSvg from '../../../views/shared/icons/_icon_status_manual_borderless.svg';
import pendingSvg from '../../../views/shared/icons/_icon_status_pending_borderless.svg';
import runningSvg from '../../../views/shared/icons/_icon_status_running_borderless.svg';
import skippedSvg from '../../../views/shared/icons/_icon_status_skipped_borderless.svg';
import successSvg from '../../../views/shared/icons/_icon_status_success_borderless.svg';
import warningSvg from '../../../views/shared/icons/_icon_status_warning_borderless.svg';

((gl) => {
  gl.VueStage = Vue.extend({
    data() {
      const svgsDictionary = {
        icon_status_canceled: canceledSvg,
        icon_status_created: createdSvg,
        icon_status_failed: failedSvg,
        icon_status_manual: manualSvg,
        icon_status_pending: pendingSvg,
        icon_status_running: runningSvg,
        icon_status_skipped: skippedSvg,
        icon_status_success: successSvg,
        icon_status_warning: warningSvg,
      };

      return {
        builds: '',
        spinner: '<span class="fa fa-spinner fa-spin"></span>',
        svg: svgsDictionary[this.stage.status.icon],
      };
    },

    props: {
      stage: {
        type: Object,
        required: true,
      },
    },
    methods: {
      fetchBuilds(e) {
        const areaExpanded = e.currentTarget.attributes['aria-expanded'];

        if (areaExpanded && (areaExpanded.textContent === 'true')) return null;

        return this.$http.get(this.stage.dropdown_path)
          .then((response) => {
            this.builds = JSON.parse(response.body).html;
          }, () => {
            const flash = new Flash('Something went wrong on our end.');
            return flash;
          });
      },
      keepGraph(e) {
        const { target } = e;

        if (target.className.indexOf('js-ci-action-icon') >= 0) return null;

        if (
          target.parentElement &&
          (target.parentElement.className.indexOf('js-ci-action-icon') >= 0)
        ) return null;

        return e.stopPropagation();
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
      triggerButtonClass() {
        return `mini-pipeline-graph-dropdown-toggle has-tooltip js-builds-dropdown-button ci-status-icon-${this.stage.status.group}`;
      },
    },
    template: `
      <div>
        <button
          @click='fetchBuilds($event)'
          :class="triggerButtonClass"
          :title='stage.title'
          data-placement="top"
          data-toggle="dropdown"
          type="button"
          :aria-label="stage.title">
          <span v-html="svg" aria-hidden="true"></span>
          <i class="fa fa-caret-down" aria-hidden="true"></i>
        </button>
        <ul class="dropdown-menu mini-pipeline-graph-dropdown-menu js-builds-dropdown-container">
          <div class="arrow-up" aria-hidden="true"></div>
          <div
            @click='keepGraph($event)'
            :class="dropdownClass"
            class="js-builds-dropdown-list scrollable-menu"
            v-html="buildsOrSpinner">
          </div>
        </ul>
      </div>
    `,
  });
})(window.gl || (window.gl = {}));
