require 'dotenv'
Dotenv.load('.cerebrum.env')
require_relative 'job'
require_relative 'task'
require_relative './lib/cloud_powers/aws_resources'
require_relative './lib/cloud_powers/auth'
require_relative './lib/cloud_powers/delegator'
require_relative './lib/cloud_powers/helper'
require_relative './lib/cloud_powers/self_awareness'
require_relative './lib/cloud_powers/smash_error'
require_relative './lib/cloud_powers/storage'
require_relative './lib/cloud_powers/synapse/pipe'
require_relative './lib/cloud_powers/synapse/queue'
require 'byebug'

module Smash
  class Cerebrum
    extend Delegator
    include Smash::CloudPowers::Auth
    include Smash::CloudPowers::AwsResources
    include Smash::CloudPowers::Helper
    include Smash::CloudPowers::SelfAwareness
    include Smash::CloudPowers::Storage
    include Smash::CloudPowers::Synapse

    attr_accessor :neuron_ids

    def initialize
      # begin
        @neuron_ids = []
        logger.info "Cerebrum waking..."
        # Smash::CloudPowers::SmashError.build(:ruby, :workflow, :task)
        get_awareness!
        # @status_thread = Thread.new do
          # send_frequent_status_updates(interval: 15, identity: 'cerebrum')
        # end
        byebug
        until should_stop? do work end
      # rescue Exception => e
      #   error_message = format_error_message(e)
      #   logger.fatal "Rescued in initialize method: creyap...#{error_message}"
      #   die!
      # end
    end

    def more_work?
      get_count(:backlog) > 0
    end

    def process(job)
      logger.info("Job found: #{job.message_body}")

      pipe_to(:status_stream) do
        job.sitrep(content: 'workflowStarted', extraInfo: job.params)
      end

      until job.done?
        job.workflow.next!
        pipe_to(:status_stream) do
          job.sitrep(content: 'workflowInProgress', extraInfo: { state: job.state })
        end
        # TODO: Add the workflow back in right here.
        job.run
        @neuron_ids.concat(job.neuron_ids)
      end
    end

    def process_invalid(job)
      logger.info "invalid job:\n#{job.inspect}"
      sqs.delete_message(
        queue_url: backlog_address,
        receipt_handle: job.receipt_handle
      )
      # TODO: make sure this is sending a message to needs_attention too
    end

    def should_stop?
      time_is_up? ? more_work? : false
    end

    def time_is_up?
      # returns true when the hour mark approaches
      an_hours_time = 60 * 60
      five_minutes_time = 60 * 5

      return false if run_time < five_minutes_time
      run_time % an_hours_time < five_minutes_time
    end

    def work
      possible_job = pluck_message(:job_requests) # FIX: pluck doesn't delete
      byebug
      job = Job.build(@instance_id, possible_job)
      job.valid? ? process(job) : process_invalid(job)
    end
  end
end

Smash::Cerebrum.new
