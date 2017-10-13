import Vue from 'vue';
import component from 'ee/vue_merge_request_widget/components/states/mr_widget_rebase.vue';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Merge request widget rebase component', () => {
  let Component;
  let vm;
  beforeEach(() => {
    Component = Vue.extend(component);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('While rebasing', () => {
    it('should show progress message', () => {
      vm = mountComponent(Component, {
        mr: { rebaseInProgress: true },
        service: {},
      });

      expect(
        vm.$el.querySelector('.rebase-state-find-class-convention span').textContent.trim(),
      ).toContain('Rebase in progress');
    });
  });

  describe('With permissions', () => {
    beforeEach(() => {
      vm = mountComponent(Component, {
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: true,
        },
        service: {},
      });
    });

    it('it should render rebase button and warning message', () => {
      const text = vm.$el.querySelector('.rebase-state-find-class-convention span').textContent.trim();
      expect(text).toContain('Fast-forward merge is not possible.');
      expect(text).toContain('Rebase the source branch onto the target branch or merge target');
      expect(text).toContain('branch into source branch to allow this merge request to be merged.');
    });

    it('it should render error message when it fails', (done) => {
      vm.rebasingError = 'Something went wrong!';

      Vue.nextTick(() => {
        expect(
          vm.$el.querySelector('.rebase-state-find-class-convention span').textContent.trim(),
        ).toContain('Something went wrong!');
        done();
      });
    });
  });

  describe('Without permissions', () => {
    it('should render a message explaining user does not have permissions', () => {
      vm = mountComponent(Component, {
        mr: {
          rebaseInProgress: false,
          canPushToSourceBranch: false,
          targetBranch: 'foo',
        },
        service: {},
      });

      const text = vm.$el.querySelector('.rebase-state-find-class-convention span').textContent.trim();

      expect(text).toContain('Fast-forward merge is not possible.');
      expect(text).toContain('Rebase the source branch onto');
      expect(text).toContain('foo');
      expect(text).toContain('to allow this merge request to be merged.');
    });
  });
});