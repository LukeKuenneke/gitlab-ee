<script>
  import arrowSvg from 'icons/_arrow_mini_pipeline_graph.svg';
  import { borderlessStatusIconEntityMap } from '../../vue_shared/ci_status_icons';
  import ciStatus from './ci_icon.vue';
  import tooltip from '../directives/tooltip';

  export default {
    props: {
      triggeredBy: {
        type: Array,
        required: false,
        default: () => [],
      },
      triggered: {
        type: Array,
        required: false,
        default: () => [],
      },
      pipelinePath: {
        type: String,
        required: false,
        default: '',
      },
    },
    data() {
      return {
        arrowSvg,
        maxRenderedPipelines: 3,
      };
    },
    directives: {
      tooltip,
    },
    components: {
      ciStatus,
    },
    computed: {
      // Exactly one of these (triggeredBy and triggered) must be truthy. Never both. Never neither.
      isUpstream() {
        return !!this.triggeredBy.length && !this.triggered.length;
      },
      isDownstream() {
        return !this.triggeredBy.length && !!this.triggered.length;
      },
      linkedPipelines() {
        return this.isUpstream ? this.triggeredBy : this.triggered;
      },
      totalPipelineCount() {
        return this.linkedPipelines.length;
      },
      linkedPipelinesTrimmed() {
        return (this.totalPipelineCount > this.maxRenderedPipelines) ?
          this.linkedPipelines.slice(0, this.maxRenderedPipelines) :
          this.linkedPipelines;
      },
      shouldRenderCounter() {
        return this.isDownstream && this.linkedPipelines.length > this.maxRenderedPipelines;
      },
      counterLabel() {
        return `+${this.linkedPipelines.length - this.maxRenderedPipelines}`;
      },
      counterTooltipText() {
        return `${this.counterLabel} more downstream pipelines`;
      },
    },
    methods: {
      pipelineTooltipText(pipeline) {
        return `${pipeline.project.name} - ${pipeline.details.status.label}`;
      },
      getStatusIcon(icon) {
        return borderlessStatusIconEntityMap[icon];
      },
      triggerButtonClass(group) {
        return `ci-status-icon-${group}`;
      },
    },
  };
</script>

<template>
  <span
    v-if="linkedPipelines"
    class="linked-pipeline-mini-list"
    :class="{
      'is-upstream' : isUpstream,
      'is-downstream': isDownstream
    }">

    <span
      class="arrow-icon"
      v-if="isDownstream"
      v-html="arrowSvg"
      aria-hidden="true">
    </span>

    <a
      v-for="(pipeline, index) in linkedPipelinesTrimmed"
      v-tooltip
      class="linked-pipeline-mini-item"
      :key="pipeline.id"
      :href="pipeline.path"
      :title="pipelineTooltipText(pipeline)"
      data-placement="top"
      data-container="body"
      :class="triggerButtonClass(pipeline.details.status.group)"
      v-html="getStatusIcon(pipeline.details.status.icon)">
    </a>

    <a
      v-if="shouldRenderCounter"
      v-tooltip
      class="linked-pipelines-counter linked-pipeline-mini-item"
      :title="counterTooltipText"
      :href="pipelinePath"
      data-placement="top"
      data-container="body">
      {{ counterLabel }}
    </a>

    <span
      class="arrow-icon"
      v-if="isUpstream"
      v-html="arrowSvg"
      aria-hidden="true">
    </span>
  </span>
</template>
