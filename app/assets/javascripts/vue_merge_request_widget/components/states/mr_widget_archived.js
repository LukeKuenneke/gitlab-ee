import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetArchived',
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
          This project is archived, write access has been disabled
        </span>
      </div>
    </div>
  `,
};
