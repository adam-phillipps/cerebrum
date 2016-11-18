re 'dotenv'
# Dotenv.load('.cerebrum.env')
require 'cloud_powers'

module Smash
  class Install
    include Smash::CloudPowers

    def initialize
      start_config('.cereibrum.env')
    end
  end
end

Smash::Install.new
