<script>
  import epicHeader from './epic_header.vue';
  import issuableApp from '../../../issue_show/components/app.vue';

  export default {
    name: 'epicShowApp',
    components: {
      epicHeader,
      issuableApp,
    },
    created() {
      // TODO: Get mock data from backend
      this.author = {
        url: 'test.com',
        src: 'http://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=48&d=identicon',
        username: '@root',
        name: 'Administrator',
      };
      this.created = (new Date()).toISOString();

      this.canUpdate = true;
      this.canDestroy = true;
      this.endpoint = '/gitlab-org/gitlab-ce/issues/1';
      this.issuableRef = '';
      this.initialTitleHtml = '';
      this.initialTitleText = '';
      this.initialDescriptionHtml = '';
      this.initialDescriptionText = '';
      this.issuableTemplates = [];
      this.markdownPreviewPath = '';
      this.markdownDocsPath = '';
      this.projectPath = '';
      this.projectNamespace = '';
      this.updatedAt = '';
      this.updatedByName = '';
      this.updatedByPath = '';
    },
  };
</script>

<template>
  <div>
    <epic-header
      :author="author"
      :created="created"
      :can-delete="canDestroy"
    />
    <div class="issuable-details detail-page-description content-block">
      <issuable-app
        :can-update="canUpdate"
        :can-destroy="canDestroy"
        :endpoint="endpoint"
        :issuable-ref="issuableRef"
        :initial-title-html="initialTitleHtml"
        :initial-title-text="initialTitleText"
        :initial-description-html="initialDescriptionHtml"
        :initial-description-text="initialDescriptionText"
        :issuable-templates="issuableTemplates"
        :markdown-preview-path="markdownPreviewPath"
        :markdown-docs-path="markdownDocsPath"
        :project-path="projectPath"
        :project-namespace="projectNamespace"
        :updated-at="updatedAt"
        :updated-by-name="updatedByName"
        :updated-by-path="updatedByPath"
        :show-inline-edit-button="true"
      />
    </div>
  </div>
</template>
