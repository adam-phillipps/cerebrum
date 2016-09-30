require 'spec_helper'
require 'cloud_powers'
require_relative '../cerebrum'

describe Cerebrum do
  before(:all) do
    @Cerebrum = Smash::Cerebrum.new
  end

  it 'should be able to determine if more work exists' do
    existing_count = Synapse::Queue.get_count(:job_requests) > 0
    expect(@cerebrum.more_work?).to eql(existing_count)
  end

  it 'should be able to'
end
