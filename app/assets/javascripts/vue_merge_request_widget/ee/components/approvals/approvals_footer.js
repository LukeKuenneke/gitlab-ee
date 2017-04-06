import pendingAvatarSvg from 'icons/_icon_dotted_circle.svg';
import LinkToMemberAvatar from '~/vue_shared/components/link_to_member_avatar';
import eventHub from '../../../event_hub';

export default {
  name: 'approvals-footer',
  props: {
    mr: {
      type: Object,
      required: true,
    },
    service: {
      type: Object,
      required: true,
    },
    approvedBy: {
      type: Array,
      required: false,
    },
    approvalsLeft: {
      type: Number,
      required: false,
    },
    userCanApprove: {
      type: Boolean,
      required: false,
    },
    userHasApproved: {
      type: Boolean,
      required: false,
    },
    suggestedApprovers: {
      type: Array,
      required: false,
    },
  },
  data() {
    return {
      unapproving: false,
      pendingAvatarSvg,
    };
  },
  components: {
    'link-to-member-avatar': LinkToMemberAvatar,
  },
  computed: {
    showUnapproveButton() {
      return this.userHasApproved && !this.userCanApprove;
    },
  },
  methods: {
    unapproveMergeRequest() {
      const flashErrorMessage = 'An error occured while removing your approval.';

      this.unapproving = true;
      this.service.unapproveMergeRequest()
        .then((data) => {
          this.mr.setApprovals(data);
          this.unapproving = false;
        })
        .catch(() => new Flash(flashErrorMessage));
    },
  },
  template: `
    <div class='approved-by-users approvals-footer clearfix mr-info-list'>
      <div class='legend'></div>
      <p>
        <span class='approvers-prefix'> Approved by </span>
        <span class='approvers-list' v-for='approver in approvedBy'>
          <link-to-member-avatar
            extra-link-class='approver-avatar'
            :avatar-url='approver.user.avatar_url'
            :display-name='approver.user.name'
            :profile-url='approver.user.web_url'
            :show-tooltip='true'>
          </link-to-member-avatar>
        </span>
        <span class='potential-approvers-list' v-for='n in approvalsLeft'>
          <link-to-member-avatar
            :clickable='false'
            :avatar-html='pendingAvatarSvg'
            :show-tooltip='false'
            extra-link-class='hide-asset'>
          </link-to-member-avatar>
        </span>
        <span class='unapprove-btn-wrap' v-if='showUnapproveButton'>
          <button
            :disabled='unapproving'
            @click='unapproveMergeRequest'
            class='btn btn-sm'>
            Remove your approval
          </button>
        </span>
      </p>
    </div>
  `,
};
