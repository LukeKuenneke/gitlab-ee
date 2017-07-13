import statusIcon from '../mr_widget_status_icon';
import eventHub from '../../event_hub';

export default {
  name: 'MRWidgetFailedToMerge',
  props: {
    mr: { type: Object, required: true },
  },
  data() {
    return {
      timer: 10,
      isRefreshing: false,
    };
  },
  mounted() {
    setInterval(() => {
      this.updateTimer();
    }, 1000);
  },
  created() {
    eventHub.$emit('DisablePolling');
  },
  computed: {
    timerText() {
      return this.timer > 1 ? `${this.timer} seconds` : 'a second';
    },
  },
  methods: {
    refresh() {
      this.isRefreshing = true;
      eventHub.$emit('MRWidgetUpdateRequested');
      eventHub.$emit('EnablePolling');
    },
    updateTimer() {
      this.timer = this.timer - 1;

      if (this.timer === 0) {
        this.refresh();
      }
    },
  },
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <template v-if="isRefreshing">
        <div class="mr-widget-icon">
          <i
          class="fa fa-spinner fa-spin"
          aria-hidden="true" />
        </div>
        <span class="media-body bold js-refresh-label">
          Refreshing now
        </span>
      </template>
      <template v-else>
        <status-icon status="failed" />
        <div class="media-body space-children">
          <button
            class="btn btn-success btn-small"
            disabled="true"
            type="button">
            Merge
          </button>
          <span class="bold">
            <span
              class="has-error-message"
              v-if="mr.mergeError">
              {{mr.mergeError}}.
            </span>
            <span v-else>Merge failed.</span>
            <span
              :class="{ 'has-custom-error': mr.mergeError }">
              Refreshing in {{timerText}} to show the updated status...
            </span>
          </span>
          <span class="align-items-center">
            <button
              @click="refresh"
              class="btn btn-default btn-xs js-refresh-button"
              type="button">
              Refresh now
            </button>
          </span>
        </div>
      </template>
    </div>
  `,
};
