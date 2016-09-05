require 'dotenv'
Dotenv.load('.cerebrum.env')
require_relative 'auth'
require_relative 'self_awareness'
require_relative 'synapse'

module Smash
  class Cerebrum
    include Smash::CloudPowers::Auth
    include Smash::CloudPowers::AwsResources
    include Smash::CloudPowers::Helper
    include Smash::CloudPowers::SelfAwareness
    include Smash::CloudPowers::Synapse
    include Smash::Delegator

    def initialize
      begin
        logger.info "Cerebrum waking..."
        # Smash::CloudPowers::SmashError.build(:ruby, :workflow, :task)
        get_awareness!

        @status_thread = Thread.new do
          send_frequent_status_updates(interval: 15, identity: 'cerebrum')
        end

        poll_for_tasks
      rescue Exception => e
        error_message = format_error_message(e)
        logger.fatal "Rescued in initialize method: creyap...#{error_message}"
        die!
      end
    end

    def work

    end

    def poll_for_tasks
      loop do

      end
    end

    def backlog_poller_config(opts = {})
      {
        idle_timeout: 60,
        wait_time_seconds: nil,
        max_number_of_messages: 1,
        visibility_timeout: 10
      }.merge(opts)
    end
  end
end
