require_relative 'cerebrum'

if __FILE__==$0
  PROJECT_ROOT=`pwd`
  # this will only run if the script was the main, not load'd or require'd
  # Any init stuff or values can happen here and cloud_powers is available
  # to get a task for this Cerebrum too.
  # For now, this helps with testing.  Cerebrum used to get run on initialization
  # which made it hard to unit test
  Smash::Cerebrum.new.start!
end
