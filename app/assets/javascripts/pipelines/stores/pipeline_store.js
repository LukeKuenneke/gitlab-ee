const mockTriggerers = [
  { id: 111, path: 'hello/world/tho', project_name: 'GitLab Shell', details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
];

const mockTriggereds = [
  { id: 111, path: 'hello/world/tho', project: { name: 'GitLab EE' }, details: { status: { icon: 'icon_status_failed', group: 'failed' } } },
  { id: 111, path: 'hello/world/tho', project: { name: 'Gitaly' }, details: { status: { icon: 'icon_status_pending', group: 'pending' } } },
  { id: 111, path: 'hello/world/tho', project: { name: 'GitHub' }, details: { status: { icon: 'icon_status_success', group: 'success' } } },
];

export default class PipelineStore {
  constructor() {
    this.state = {};

    this.state.graph = [];
    this.state.triggered = [];
    this.state.triggerer = [];
  }

  storeGraph(graph = []) {
    // single job in first stage
   // graph[0].groups = [graph[0].groups[0]];

    // multiple jobs in last stage
    graph[3].groups.push(graph[0].groups[0]);
    this.state.graph = graph;
    this.state.triggerer = mockTriggerers;

    // single triggered
    // this.state.triggered = [mockTriggereds[0]];
    this.state.triggered = mockTriggereds;
  }
}
