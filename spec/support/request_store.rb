RSpec.configure do |config|
  config.before(:each) do
    RequestStore.clear!
  end

  config.around(:each, :with_request_store) do |example|
    RequestStore.begin!
    example.run
    RequestStore.end!
  end
end
