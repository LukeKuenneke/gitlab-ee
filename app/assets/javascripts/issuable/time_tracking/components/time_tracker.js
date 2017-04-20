import timeTrackingCollapsedState from './collapsed_state';
import timeTrackingComparisonPane from './comparison_pane';

export default {
  name: 'IssuableTimeTracker',
  props: {
    time_estimate: {
      type: Number,
      required: true,
      default: 0,
    },
    time_spent: {
      type: Number,
      required: true,
      default: 0,
    },
    human_time_estimate: {
      type: String,
      required: false,
    },
    human_time_spent: {
      type: String,
      required: false,
    },
    docsUrl: {
      type: String,
      required: true,
    },
  },
  data() {
    return {
      showHelp: false,
    };
  },
  components: {
    'time-tracking-collapsed-state': timeTrackingCollapsedState,
    'time-tracking-comparison-pane': timeTrackingComparisonPane,
  },
  computed: {
    timeSpent() {
      return this.time_spent;
    },
    timeEstimate() {
      return this.time_estimate;
    },
    timeEstimateHumanReadable() {
      return this.human_time_estimate;
    },
    timeSpentHumanReadable() {
      return this.human_time_spent;
    },
    hasTimeSpent() {
      return !!this.timeSpent;
    },
    hasTimeEstimate() {
      return !!this.timeEstimate;
    },
    showComparisonState() {
      return this.hasTimeEstimate && this.hasTimeSpent;
    },
    showEstimateOnlyState() {
      return this.hasTimeEstimate && !this.hasTimeSpent;
    },
    showSpentOnlyState() {
      return this.hasTimeSpent && !this.hasTimeEstimate;
    },
    showNoTimeTrackingState() {
      return !this.hasTimeEstimate && !this.hasTimeSpent;
    },
    showHelpState() {
      return !!this.showHelp;
    },
  },
  methods: {
    toggleHelpState(show) {
      this.showHelp = show;
    },
  },
  template: `
    <div
      class="time_tracker time-tracking-component-wrap"
      v-cloak
    >
      <time-tracking-collapsed-state
        :show-comparison-state="showComparisonState"
        :show-no-time-tracking-state="showNoTimeTrackingState"
        :show-help-state="showHelpState"
        :show-spent-only-state="showSpentOnlyState"
        :show-estimate-only-state="showEstimateOnlyState"
        :time-spent-human-readable="timeSpentHumanReadable"
        :time-estimate-human-readable="timeEstimateHumanReadable"
      />
      <div class="title hide-collapsed">
        Time tracking
        <div
          class="help-button pull-right"
          v-if="!showHelpState"
          @click="toggleHelpState(true)"
        >
          <i
            class="fa fa-question-circle"
            aria-hidden="true"
          />
        </div>
        <div
          class="close-help-button pull-right"
          v-if="showHelpState"
          @click="toggleHelpState(false)"
        >
          <i
            class="fa fa-close"
            aria-hidden="true"
          />
        </div>
      </div>
      <div class="time-tracking-content hide-collapsed">
        <div
          class="time-tracking-estimate-only-pane"
          v-if="showEstimateOnlyState"
        >
          <span class="bold">
            Estimated:
          </span>
          {{ timeEstimateHumanReadable }}
        </div>
        <div
          class="time-tracking-spend-only-pane"
          v-if="showSpentOnlyState"
        >
          <span class="bold">Spent:</span>
          {{ timeSpentHumanReadable }}
        </div>
        <div
          class="time-tracking-no-tracking-pane"
          v-if="showNoTimeTrackingState"
        >
          <span class="no-value">
            No estimate or time spent
          </span>
        </div>
        <time-tracking-comparison-pane
          v-if="showComparisonState"
          :time-estimate="timeEstimate"
          :time-spent="timeSpent"
          :time-spent-human-readable="timeSpentHumanReadable"
          :time-estimate-human-readable="timeEstimateHumanReadable"
        />
        <transition name="help-state-toggle">
          <div
            class="time-tracking-help-state"
            v-if="showHelpState"
          >
            <div class="time-tracking-info">
              <h4>
                Track time with slash commands
              </h4>
              <p>
                Slash commands can be used in the issues description and comment boxes.
              </p>
              <p>
                <code>
                  /estimate
                </code>
                will update the estimated time with the latest command.
              </p>
              <p>
                <code>
                  /spend
                </code>
                will update the sum of the time spent.
              </p>
              <a
                class="btn btn-default learn-more-button"
                :href="docsUrl">
                Learn more
              </a>
            </div>
          </div>
        </transition>
      </div>
    </div>
  `,
};
