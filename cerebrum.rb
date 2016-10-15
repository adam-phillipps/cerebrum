require 'dotenv'
# Dotenv.load('.cerebrum.env')
require 'cloud_powers'
require 'stubs/aws_stubs'
require 'pathname'
require 'byebug'
require_relative 'job'
require_relative 'task'

module Smash
  class Cerebrum
    include Smash::CloudPowers
    # include Smash::CloudPowers::AwsStubs
    include
    attr_accessor :neuron_ids

    # Gathers some information about the Context this Cerebrum will run in and about
    # itself and starts a status update thread
    #
    # Returns
    # +Smash::Cerebrum+
    #
    # Notes
    # * if a fatal exception occurs, the instance will terminate itself using the
    #   +#die!()+ method
    def initialize
      begin
        @neuron_ids = []
        logger.info "Cerebrum waking..."

        # @status_thread = Thread.new do
        #   send_frequent_status_updates(interval: 15, identity: 'cerebrum')
        # end
      rescue Exception => e
        error_message = format_error_message(e)
        logger.fatal "Rescued in initialize method: creyap...#{error_message}"
        die!
      end
    end

    def self.create
      cerebrum = new
      Dotenv.load("#{cerebrum.project_root}/.cerebrum.env")
      # TESTING
      cerebrum.ec2(Smash::CloudPowers::AwsStubs.node_stub)
      cerebrum.sqs(Smash::CloudPowers::AwsStubs.queue_stub(body: { task: 'true_roas' }.to_json))
      cerebrum.sns(Smash::CloudPowers::AwsStubs.broadcast_stub)
      cerebrum.kinesis(Smash::CloudPowers::AwsStubs.pipe_stub)
      cerebrum.boot_time
      sleep 5
      # TESTING
      cerebrum.get_awareness!
      cerebrum
    end

    # Predicate method to find out if there is work left in the +jobRequests+ queue
    #
    # Returns
    # +Boolean+
    #
    # Notes
    # * uses a count in the queue because we know each message is automatically deleted
    #   after it is read
    def more_work?
      get_queue_message_count(:job_requests) > 0
    end

    # Begin working on this job.
    # the method does these things in this order:
    # * send status message
    # * utilize the +Workflow+ to find out what thing it should do next and then does it
    # * adds ids of all Neurons it starts to the +@neuron_ids+ Array
    #
    # Parameters
    # +Smash::Job+
    #
    # Returns
    # +Array+ - Array of neuron ids
    #
    # Notes
    # * See +#pipe_to()+
    # * See +Smash::Job+
    # * See +logger()+
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

    # This method is used when it is found that the newly created job isn't
    # valid.
    #
    # Parameters
    # * +Smash::Job+
    #
    # Notes
    # * See +#backlog_address()+
    def process_invalid(job)
      logger.info "invalid job:\n#{job.inspect}"
      sqs.delete_message(
        queue_url: backlog_address,
        receipt_handle: job.receipt_handle
      )
      # TODO: make sure this is sending a message to needs_attention too
    end

    # Predicate method to find out if it's a good time for the instance to
    # stop working.  It does this by making a few checks.
    # The checks happen in this order:
    # * +#time_is_up?()+ - checks on time
    # * +#more_work?()+ - checks ratios in queues
    #
    # Returns
    # +Boolean+
    #
    # Notes
    # * See +#time_is_up?()+
    # * See +#more_work?()+
    def should_stop?
      time_is_up? ? more_work? : false
    end

    # The method will work, in an endless loop until it is told to stop
    #
    # Returns
    # +Boolean+
    #
    # Notes
    # * See +#should_stop?+
    # * See +#work()+
    def start!
      until should_stop? do work end
    end

    # Predicate method to give you awareness of the time the instance has
    # been running
    #
    # Returns
    # +Boolean+
    #
    # Notes
    # * returns +true+ when:
    # * * there is 5 minutes or less until it has been 1 hour from the time the instance was started
    #     almost an hour ago or when the last hour mark from that original starting time is happening
    # * returns false when:
    # * * otherwise i.e. this instance has been running for less than an hour
    def time_is_up?
      an_hours_time = 60 * 60
      five_minutes_time = 60 * 5

      return false if run_time < five_minutes_time
      run_time % an_hours_time < five_minutes_time
    end

    # Begin working on this Job or Project by getting a message from the +jobRequests+ queue
    # and calling +Smash::Job.build()+ with the params from the message from above
    # and finally processing the job, whether it's valid or not
    #
    # Notes
    # * See +#pluck_message()+
    # * See +#build()+
    # * See +#valid?()+
    # * See +#process()+
    # * See +#process_invalid()+
    def work
      possible_job = pluck_queue_message(:job_requests) # FIX: pluck doesn't delete
      job = Job.build(@instance_id, possible_job)
      job.valid? ? process(job) : process_invalid(job)
    end
  end
end

# this will only run if the script was the main, not load'd or require'd
if __FILE__==$0
  cerebrum = Smash::Cerebrum.create
  cerebrum.start!
end
