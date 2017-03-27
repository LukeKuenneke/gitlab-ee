/**
 * Render environments table.
 *
 * Dumb component used to render top level environments and
 * the folder view.
 */
import EnvironmentTableRowComponent from './environment_item';
import DeployBoard from './deploy_board_component';

export default {
  components: {
    'environment-item': EnvironmentTableRowComponent,
    DeployBoard,
  },

  props: {
    environments: {
      type: Array,
      required: true,
      default: () => ([]),
    },

    canReadEnvironment: {
      type: Boolean,
      required: false,
      default: false,
    },

    canCreateDeployment: {
      type: Boolean,
      required: false,
      default: false,
    },

    toggleDeployBoard: {
      type: Function,
      required: false,
      default: () => {},
    },

    store: {
      type: Object,
      required: false,
      default: () => ({}),
    },

    service: {
      type: Object,
      required: true,
      default: () => ({}),
    },

    canRenderDeployBoard: {
      type: Boolean,
      required: true,
    },
  },

  computed: {
    shouldRenderDeployBoard() {
      return this.canRenderDeployBoard &&
        this.model.hasDeployBoard &&
        this.model.isDeployBoardVisible;
    },
  },

  template: `
    <table class="table ci-table">
      <thead>
        <tr>
          <th class="environments-name">Environment</th>
          <th class="environments-deploy">Last deployment</th>
          <th class="environments-build">Job</th>
          <th class="environments-commit">Commit</th>
          <th class="environments-date">Updated</th>
          <th class="environments-actions"></th>
        </tr>
      </thead>
      <tbody>
        <template v-for="model in environments"
          v-bind:model="model">

          <tr is="environment-item"
            :model="model"
            :can-create-deployment="canCreateDeployment"
            :can-read-environment="canReadEnvironment"
            :toggleDeployBoard="toggleDeployBoard"
            :service="service"></tr>

          <tr v-if="shouldRenderDeployBoard" class="js-deploy-board-row">
            <td colspan="6" class="deploy-board-container">
              <deploy-board
                :store="store"
                :service="service"
                :environmentID="model.id"
                :deployBoardData="model.deployBoardData"
                :endpoint="model.rollout_status_path" />
            </td>
          </tr>
        </template>
      </tbody>
    </table>
  `,
};
