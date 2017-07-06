import statusIcon from '../mr_widget_status_icon';

export default {
  name: 'MRWidgetUnresolvedDiscussions',
  props: {
    mr: { type: Object, required: true },
  },
  components: {
    statusIcon,
  },
  template: `
    <div class="mr-widget-body media">
      <status-icon status="failed" />
      <div class="media-body">
        <span class="bold">
          There are unresolved discussions. Please resolve these discussions
        </span>
        <button
          type="button"
          class="btn btn-success btn-xs"
          disabled="true">
          Merge
        </button>
        <a
          v-if="mr.createIssueToResolveDiscussionsPath"
          :href="mr.createIssueToResolveDiscussionsPath"
          class="btn btn-default btn-xs js-create-issue">
          Create an issue to resolve them later
        </a>
      </div>
    </div>
  `,
};
