import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetSHAMismatch',
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="failed" />
      <div class="media-body space-children">
        <button
          type="button"
          class="btn btn-success btn-small"
          disabled="true">
          Merge
        </button>
        <span class="bold">
          The source branch HEAD has recently changed. Please reload the page and review the changes before merging
        </span>
      </div>
    </div>
  `,
};
