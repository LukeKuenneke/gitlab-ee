/* global Flash */

export default {
  name: 'approvals-body',
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
      approving: false,
    };
  },
  computed: {
    approvalsRequiredStringified() {
      const baseString = `${this.approvalsLeft} more approval`;
      return this.approvalsLeft === 1 ? baseString : `${baseString}s`;
    },
    approverNamesStringified() {
      const approvers = this.suggestedApprovers;

      if (!approvers) {
        return '';
      }

      return approvers.length === 1 ? approvers[0].name :
        approvers.reduce((memo, curr, index) => {
          const nextMemo = `${memo}${curr.name}`;

          if (index === approvers.length - 2) { // second to last index
            return `${nextMemo} or `;
          } else if (index === approvers.length - 1) { // last index
            return nextMemo;
          }

          return `${nextMemo}, `;
        }, '');
    },
    showApproveButton() {
      return this.userCanApprove && !this.userHasApproved;
    },
    showSuggestedApprovers() {
      return this.suggestedApprovers && this.suggestedApprovers.length;
    },
  },
  methods: {
    approveMergeRequest() {
      const flashErrorMessage = 'An error occured while submitting your approval.';

      this.approving = true;
      this.service.approveMergeRequest()
        .then((data) => {
          this.mr.setApprovals(data);
          this.approving = false;
        })
        .catch(() => new Flash(flashErrorMessage));
    },
  },
  template: `
    <div class="approvals-body">
      <div v-if="showApproveButton" class="approvals-approve-button-wrap">
        <button
          :disabled="approving"
          @click="approveMergeRequest"
          class="btn btn-primary approve-btn">
          Approve
        </button>
      </div>
      <p class="approvals-required-text"> Requires {{ approvalsRequiredStringified }}
        <span v-if="showSuggestedApprovers"> (from {{ approverNamesStringified }}) </span>
      </p>
    </div>
  `,
};
