import Vue from 'vue';
import { statusIconEntityMap } from '~/vue_shared/ci_status_icons';
import pipelineComponent from '~/vue_merge_request_widget/components/mr_widget_pipeline';
import mockData from '../mock_data';

const createComponent = (mr) => {
  const Component = Vue.extend(pipelineComponent);
  return new Component({
    el: document.createElement('div'),
    propsData: { mr },
  });
};

describe('MRWidgetPipeline', () => {
  describe('props', () => {
    it('should have props', () => {
      const { mr } = pipelineComponent.props;

      expect(mr.type instanceof Object).toBeTruthy();
      expect(mr.required).toBeTruthy();
    });
  });

  describe('components', () => {
    it('should have components added', () => {
      expect(pipelineComponent.components['pipeline-stage']).toBeDefined();
      expect(pipelineComponent.components.ciIcon).toBeDefined();
    });
  });

  describe('computed', () => {
    describe('svg', () => {
      it('should have the proper SVG icon', () => {
        const vm = createComponent({ pipeline: mockData.pipeline });

        expect(vm.svg).toEqual(statusIconEntityMap.icon_status_failed);
      });
    });

    describe('hasCIError', () => {
      it('should return false when there is no CI error', () => {
        const vm = createComponent({
          pipeline: mockData.pipeline,
          hasCI: true,
          ciStatus: 'success',
        });

        expect(vm.hasCIError).toBeFalsy();
      });

      it('should return true when there is a CI error', () => {
        const vm = createComponent({
          pipeline: mockData.pipeline,
          hasCI: true,
          ciStatus: null,
        });

        expect(vm.hasCIError).toBeTruthy();
      });
    });
  });

  describe('template', () => {
    let vm;
    let el;
    const { pipeline } = mockData;
    const mr = {
      hasCI: true,
      ciStatus: 'success',
      pipelineDetailedStatus: pipeline.details.status,
      pipeline,
    };

    beforeEach(() => {
      vm = createComponent(mr);
      el = vm.$el;
    });

    afterEach(() => {
      vm.$destroy();
    });

    describe('without a pipeline', () => {
      beforeEach(() => {
        vm.mr = { pipeline: null };
      });

      it('should render message with spinner', (done) => {
        Vue.nextTick()
          .then(() => {
            expect(el.querySelector('.pipeline-id')).toBe(null);
            expect(el.innerText.trim()).toBe('Waiting for pipeline...');
            expect(el.querySelectorAll('i.fa.fa-spinner.fa-spin').length).toBe(1);
            done();
          })
          .then(done)
          .catch(done.fail);
      });
    });

    it('should render template elements correctly', () => {
      expect(el.classList.contains('mr-widget-heading')).toBeTruthy();
      expect(el.querySelectorAll('.ci-status-icon.ci-status-icon-success').length).toEqual(1);
      expect(el.querySelector('.pipeline-id').textContent).toContain(`#${pipeline.id}`);
      expect(el.innerText).toContain('passed');
      expect(el.innerText).toContain('with stages');
      expect(el.querySelector('.pipeline-id').getAttribute('href')).toEqual(pipeline.path);
      expect(el.querySelectorAll('.stage-container').length).toEqual(2);
      expect(el.querySelector('.js-ci-error')).toEqual(null);
      expect(el.querySelector('.js-commit-link').getAttribute('href')).toEqual(pipeline.commit.commit_path);
      expect(el.querySelector('.js-commit-link').textContent).toContain(pipeline.commit.short_id);
      expect(el.querySelector('.js-mr-coverage').textContent).toContain(`Coverage ${pipeline.coverage}%.`);
    });

    it('should list single stage', (done) => {
      pipeline.details.stages.splice(0, 1);

      Vue.nextTick()
        .then(() => {
          expect(el.querySelectorAll('.stage-container button').length).toEqual(1);
          expect(el.innerText).toContain('with stage');
        })
        .then(done)
        .catch(done.fail);
    });

    it('should not have stages when there is no stage', (done) => {
      vm.mr.pipeline.details.stages = [];

      Vue.nextTick()
        .then(() => {
          expect(el.querySelectorAll('.stage-container button').length).toEqual(0);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should not have coverage text when pipeline has no coverage info', (done) => {
      vm.mr.pipeline.coverage = null;

      Vue.nextTick()
        .then(() => {
          expect(el.querySelector('.js-mr-coverage')).toEqual(null);
        })
        .then(done)
        .catch(done.fail);
    });

    it('should show CI error when there is a CI error', (done) => {
      vm.mr.ciStatus = null;

      Vue.nextTick()
        .then(() => {
          expect(el.querySelectorAll('.js-ci-error').length).toEqual(1);
          expect(el.innerText).toContain('Could not connect to the CI server');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
