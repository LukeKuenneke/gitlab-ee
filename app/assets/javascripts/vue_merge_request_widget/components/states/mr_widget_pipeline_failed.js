import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetPipelineBlocked',
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="failed" />
      <div class="media-body">
        <span class="bold">
          The pipeline for this merge request failed. Please retry the job or push a new commit to fix the failure
        </span>
        <button
          class="btn btn-success btn-xs"
          disabled="true"
          type="button">
          Merge
        </button>
      </div>
    </div>
  `,
};
