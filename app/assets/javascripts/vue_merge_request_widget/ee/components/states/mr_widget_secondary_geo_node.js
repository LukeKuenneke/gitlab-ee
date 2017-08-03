import statusIcon from '../../../components/mr_widget_status_icon';

export default {
  props: {
    mr: {
      type: Object,
      required: true,
    },
  },
  components: {
    statusIcon,
  },
  template: `
    <div class="media">
      <status-icon status="failed" showDisabledButton />
      <div class="media-body">
        <span class="bold">
          Merge requests are read-only in a secondary Geo node
        </span>
        <a
          :href="mr.geoSecondaryHelpPath"
          data-title="About this feature"
          data-toggle="tooltip"
          data-placement="bottom"
          target="_blank"
          rel="noopener noreferrer nofollow"
          data-container="body">
          <i class="fa fa-question-circle"></i>
        </a>
      </div>
    </div>
  `,
};
