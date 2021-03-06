<script>
import GfmAutoComplete from '~/gfm_auto_complete';
import loadingIcon from '~/vue_shared/components/loading_icon.vue';
import eventHub from '../event_hub';
import issueToken from './issue_token.vue';

export default {
  name: 'AddIssuableForm',

  props: {
    inputValue: {
      type: String,
      required: true,
    },
    pendingReferences: {
      type: Array,
      required: false,
      default: () => [],
    },
    autoCompleteSources: {
      type: Object,
      required: false,
      default: () => ({}),
    },
    isSubmitting: {
      type: Boolean,
      required: false,
      default: false,
    },
  },

  data() {
    return {
      isInputFocused: false,
      isAutoCompleteOpen: false,
    };
  },

  components: {
    issueToken,
    loadingIcon,
  },

  computed: {
    inputPlaceholder() {
      return 'Paste issue link or <#issue id>';
    },
    isSubmitButtonDisabled() {
      return (this.inputValue.length === 0 && this.pendingReferences.length === 0)
        || this.isSubmitting;
    },
  },

  methods: {
    onInput() {
      const value = this.$refs.input.value;
      eventHub.$emit('addIssuableFormInput', value, $(this.$refs.input).caret('pos'));
    },
    onFocus() {
      this.isInputFocused = true;
    },
    onBlur() {
      this.isInputFocused = false;

      // Avoid tokenizing partial input when clicking an autocomplete item
      if (!this.isAutoCompleteOpen) {
        const value = this.$refs.input.value;
        eventHub.$emit('addIssuableFormBlur', value);
      }
    },
    onAutoCompleteToggled(isOpen) {
      this.isAutoCompleteOpen = isOpen;
    },
    onInputWrapperClick() {
      this.$refs.input.focus();
    },
    onFormSubmit() {
      const value = this.$refs.input.value;
      eventHub.$emit('addIssuableFormSubmit', value);
    },
    onFormCancel() {
      eventHub.$emit('addIssuableFormCancel');
    },
  },

  mounted() {
    const $input = $(this.$refs.input);

    this.gfmAutoComplete = new GfmAutoComplete(this.autoCompleteSources);
    this.gfmAutoComplete.setup($input, {
      issues: true,
    });
    $input.on('shown-issues.atwho', this.onAutoCompleteToggled.bind(this, true));
    $input.on('hidden-issues.atwho', this.onAutoCompleteToggled.bind(this, false));

    this.$refs.input.focus();
  },

  beforeDestroy() {
    const $input = $(this.$refs.input);
    $input.off('shown-issues.atwho');
    $input.off('hidden-issues.atwho');
    $input.off('inserted-issues.atwho', this.onInput);
  },
};
</script>

<template>
  <form @submit.prevent="onFormSubmit">
    <div
      ref="issuableFormWrapper"
      class="add-issuable-form-input-wrapper form-control"
      :class="{ focus: isInputFocused }"
      role="button"
      @click="onInputWrapperClick">
      <ul class="add-issuable-form-input-token-list">
        <li
          :key="reference"
          v-for="(reference, index) in pendingReferences"
          class="js-add-issuable-form-token-list-item add-issuable-form-token-list-item">
          <issue-token
            event-namespace="pendingIssuable"
            :id-key="index"
            :display-reference="reference"
            :can-remove="true" />
        </li>
        <li class="add-issuable-form-input-list-item">
          <input
            ref="input"
            type="text"
            class="js-add-issuable-form-input add-issuable-form-input"
            :value="inputValue"
            :placeholder="inputPlaceholder"
            @input="onInput"
            @focus="onFocus"
            @blur="onBlur" />
        </li>
      </ul>
    </div>
    <div class="add-issuable-form-actions clearfix">
      <button
        ref="addButton"
        type="submit"
        class="js-add-issuable-form-add-button btn btn-new pull-left"
        :disabled="isSubmitButtonDisabled">
        Add
        <loadingIcon
          ref="loadingIcon"
          v-if="isSubmitting"
          :inline="true"
          label="Submitting related issues" />
      </button>
      <button
        type="button"
        class="btn btn-default pull-right"
        @click="onFormCancel">
        Cancel
      </button>
    </div>
  </form>
</template>
