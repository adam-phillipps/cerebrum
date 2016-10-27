require 'cloud_powers'
require 'brain_fund/cerebrum_functions'
require 'brain_func/contexts'
require 'brain_func/workflow_factory'

module Smash
  class Job
    include BrainFunc::CerebrumFunctions
    include BrainFunc::workflow_factory
    extend CloudPowers::Delegator
    include CloudPowers::Auth
    include CloudPowers::AwsResources
    include CloudPowers::Helper
    include CloudPowers::Synapse::Pipe
    include CloudPowers::Synapse::Queue

    # self-instance-id +String+
    attr_reader  :instance_id
    # message that is used as a base for this Job
    attr_reader  :message
    # the parsed message body, containing the information about the job
    attr_reader  :message_body
    # all the other nodes this Cerebrum has started
    attr_reader  :neuron_ids
    # steps and states for this Job to follow while its alive
    attr_reader  :workflow

    def initialize(id, msg)
      @instance_id = id
      @message = msg
      @neuron_ids = []
      inject_workflow(msg[])
    end
  end
end
