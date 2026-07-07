# frozen_string_literal: true

require 'tmpdir'
require 'fileutils'
require 'logger'
require 'nti_event_bus'
require 'active_job'

ActiveJob::Base.logger = Logger.new(IO::NULL)
ActiveJob::Base.queue_adapter = :test

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.mock_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  Kernel.srand config.seed

  config.after do
    NtiEventBus.reset_configuration!
    NtiEventBus.instance_variable_set(:@registry, nil)

    adapter = ActiveJob::Base.queue_adapter
    adapter.enqueued_jobs.clear if adapter.respond_to?(:enqueued_jobs)
    adapter.performed_jobs.clear if adapter.respond_to?(:performed_jobs)
  end
end
