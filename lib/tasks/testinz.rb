require_relative '../../task'

module Smash
  class Testinz < Smash::Task
    def initialize(*args)
      puts args
    end

    def run
      puts 'sleeping'
      sleep 5
    end

    def valid?
      true
    end

    def self.create(*args)
      t = new(args)
      t
    end

    def sitrep(opts = {})
      opts
    end
  end
end
