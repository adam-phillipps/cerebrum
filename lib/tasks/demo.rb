require_relative '../../task'
require_relative '../cloud_powers/synapse/synapse'
require_relative '../cloud_powers/storage'

module Smash
  class Demo < Task
    include Smash::CloudPowers::Synapse
    include Smash::CloudPowers::Storage

    def initialize(id, msg)
      super(id, msg)
    end

    def create_messages(indexes)
      indexes.map do |index|
        { task: 'Demo', identity: index }
      end
    end

    def create_queues
      @workflow.all_states.map do |name|
        queue_name = "demo #{name}"
        create_queue(queue_name)
      end
    end

    def done?
      # TODO: this could be better
      @done
    end

    def get_indexes
      keys = search('roas-models', %r(.*\/model\/reg_model\/.*\.bin)).collect(&:key)
      indexes = []
      keys.each do |k|
        index = k.split('-').last.gsub(/\..*/, '')
        indexes.push(index) unless indexes.include? index
      end
      indexes
    end

    def identity
      @identity = 'cerebrum'
    end

    def run
      super
      messages = create_messages(get_indexes)
      backlog_name = create_queues.collect(&:queue_url).first.split('/').last
      messages.each do |message|
        send_queue_message(message, backlog_name)
      end
      byebug
      # TODO: chunks
      ids = spin_up_neurons(max_count: messages.count)
      # 5. tag instances
      # 6. monitor the Pipe and relivant Queues in that context
      # 7. send updates in the cache
      # 8. stay alive always if you're the last Cerebrum in the main Collective

      message = sitrep(
        extraInfo: @params.merge(neurons_started: ids, run_time: (Time.now.to_i - @start_time).to_s)
      )
      logger.info "Task finished #{message}"
      pipe_to(:status_stream) { message }
    end

    def sitrep(opts = {})
      opts = { extraInfo: { message: opts.to_s } } unless opts.kind_of? Hash
      custom_info = { identity: identity, url: @instance_url }.merge(opts)
      sitrep_message(custom_info)
    end
  end
end
