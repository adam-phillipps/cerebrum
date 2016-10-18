require 'cloud_powers'
require_relative 'job'

module Smash
  class Task < Smash::Job
    attr_reader :instance_url, :params

    def initialize(id, msg, opts = {})
      @params       = msg
      @instance_id  = id
      @start_time   = Time.now.to_i
      @opts = opts
      super(id, msg, opts)
    end

    def run
      # TODO: make this have a real point
      message = sitrep(
        extraInfo: @params.merge(run_time: (Time.now.to_i - @start_time).to_s)
      )
      logger.info "Task starting... #{message}"
      pipe_to(:status_stream) { message }
    end

    def valid?
      @valid ||= @params.kind_of? Hash
    end
  end
end
