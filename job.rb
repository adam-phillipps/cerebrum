require 'cloud_powers'

module Smash
  class   Job
    extend CloudPowers::Delegator
    include CloudPowers::Auth
    include CloudPowers::AwsResources
    include CloudPowers::Helper
    include CloudPowers::Synapse::Pipe
    include CloudPowers::Synapse::Queue

    attr_reader :instance_id, :message, :message_body, :neuron_ids, :workflow

    def initialize(id, msg, opts = {})
      @neuron_ids = []
      @workflow = opts.delete(:workflow) || Workflow.new
      @instance_id = id
      @message = msg
      @message_body = msg.body
    end

    def backlog
      CloudPowers::Synapse::Queue::Board.new('JobRequests')
    end

    def instance_config(opts = {})
      {
        dry_run:                  env(:testing) || false,
        image_id:                 image('crawlbotprod').image_id, # image(:neuron).image_id
        instance_type:            't2.nano',
        min_count:                opts[:max_count],
        max_count:                0,
        key_name:                 'crawlBot',
        security_groups:          ['webCrawler'],
        security_group_ids:       ['sg-940edcf2'],
        placement:                { availability_zone: 'us-west-2c' },
        disable_api_termination:  'false',
        instance_initiated_shutdown_behavior:   'terminate'
      }.merge(opts)
    end

    def spin_up_neurons(opts = {})
      ids = nil
      begin
        byebug
        response = ec2.run_instances(instance_config(opts))
        ids = response.instances.map(&:instance_id)

        ec2.wait_until(:instance_running, instance_ids: ids) do
          logger.info "waiting for #{ids.count} Neurons to start..."
        end
        tag(ids, { key: 'project', value: to_camal(self.class.to_s) })
      rescue Aws::EC2::Errors::DryRunOperation => e
        ids = (1..(opts[:max_count] || 0)).to_a.map { |n| n.to_s }
        logger.info "waiting for #{ids.count} Neurons to start..."
      end

      @neuron_ids.concat(ids)
      pipe_to(:status_stream) { sitrep(content: 'neuronsStarted', extraInfo: { ids:  ids }) }
      ids
    end

    def sitrep_message(opts = {})
      # TODO: find better implementation of merging nested hashes
      # this should be fixed with ::Helper#update_message_body
      extra_info = {}
      if opts.kind_of?(Hash) && opts[:extraInfo]
        custom_info = opts.delete(:extraInfo)
        extra_info = { 'taskRunTime' => task_run_time }.merge(custom_info)
      else
        opts = {}
      end

      sitrep_alterations = {
        type: 'SitRep',
        content: to_pascal(state),
        extraInfo: extra_info
      }.merge(opts)
      update_message_body(sitrep_alterations)
    end

    def state
      @workflow.current
    end

    def task_run_time
      # @start_time is in the Task class
      Time.now.to_i - @start_time
    end
  end
end
