import Vue from 'vue';
import LinkedPipelineComponent from '~/pipelines/components/graph/linked_pipeline.vue';
import mockData from './mock_data';

const LinkedPipeline = Vue.extend(LinkedPipelineComponent);
const mockPipeline = mockData.triggered[0];

fdescribe('Linked pipeline', () => {
  beforeEach(() => {
    this.propsData = {
      pipelineId: mockPipeline.id,
      pipelinePath: mockPipeline.path,
      pipelineStatus: mockPipeline.details.status,
      projectName: mockPipeline.project_name,
    };

    this.linkedPipeline = new LinkedPipeline({
      propsData: this.propsData,
    }).$mount();
  });

  it('should return a defined Vue component', () => {
    expect(this.linkedPipeline).toBeDefined();
  });

  it('should render a list item as the containing element', () => {
    expect(this.linkedPipeline.$el.tagName).toBe('LI');
  });

  it('should render a link', () => {
    const linkElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-link');
    expect(linkElement).not.toBeNull();
  });

  it('should link to the correct path', () => {
    const linkElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-link');
    expect(linkElement.getAttribute('href')).toBe(this.propsData.pipelinePath);
  });

  it('should render the project name', () => {
    const projectNameElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-project-name');
    expect(projectNameElement.innerText).toContain(this.propsData.projectName);
  });

  it('should render an svg within the status container', () => {
    const pipelineStatusElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-status');
    expect(pipelineStatusElement.querySelector('svg')).not.toBeNull();
  });

  it('should render the correct pipeline status icon', () => {
    const pipelineStatusElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-status');

  });

  it('should render the correct pipeline status icon style selector', () => {
    const pipelineStatusElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-status');

  });

  it('should have a ci-status child component', () => {

  });

  it('should render the pipeline id', () => {
    const pipelineIdElement = this.linkedPipeline.$el.querySelector('.linked-pipeline-id');
    expect(pipelineIdElement.innerText).toContain(`${this.propsData.pipelineId}`);
  });
});
