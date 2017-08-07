import stateMaps from '~/vue_merge_request_widget/stores/state_maps';

stateMaps.stateToComponentMap.geoSecondaryNode = 'mr-widget-geo-secondary-node';
stateMaps.stateToComponentMap.rebase = 'mr-widget-rebase';
stateMaps.statesToShowHelpWidget.push('rebase');

export default {
  stateToComponentMap: stateMaps.stateToComponentMap,
  statesToShowHelpWidget: stateMaps.statesToShowHelpWidget,
};
