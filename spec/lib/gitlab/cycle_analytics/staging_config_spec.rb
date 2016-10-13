require 'spec_helper'
require 'lib/gitlab/cycle_analytics/shared_config_spec'

describe Gitlab::CycleAnalytics::StagingConfig do
  it_behaves_like 'default query config'

  it 'has the default order' do
    expect(described_class.order).not_to eq(described_class.start_time_attrs)
  end
end
