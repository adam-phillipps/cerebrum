################################################################################
#                           Cerebrum's workflow
################################################################################
1. Check the brain_backlog                                                  *1
  - the parameters in the messages give the location of the files that the
      Cerebrum will use to create the environment for the Neurons
      - messages look like this: 
        {
          'backlog':'named_backlog',                                        *2
          'task-env':'s3-file',                                             *3
          'metadata':
            {
              'x-amz-website-redirect-location':'neuron_task_s3_location'   *4
            }                                                     
        }
  
  - The S3 object has the actual `custom_cerebrum_task.rb` for this specific
      project
  - Dynamically require/load whatever this file in the delegaor module? and stick
      it in `<path to>/<repo>/lib/`.  The file has the ratio in it instead
      of .env and other things like that
    - Create the custom project backlog, wip, count, finished queues
    - Create neurons # normal workflow (since v1 basically)
      - Tag instances with the name of the project
        - The name of the tag guarantees we'll find the correct backlog
    - Populate the custom_backlog, one message for each instance with 
        messages like this:
        {
          'extraInfo':{'any-useful-params':'or-other-good-stuff'},
          'task-env':'s3-location of task' # see *1 for details on how 
        }
      
      - neuron starts, waits for custom_backlog to be ready and then it polls 
        and grabs a message.                                                *5
          messages like this:
           {
             'extraInfo':{'any-useful-params':'or-other-good-stuff'},
             'task-env':'s3-location of task' # see *1 for details on how 
           }
      
      - the number of messages is always 1/1 for this and all other neuron 
        backlogs. The Cerebrum has to convert the ratio from the message 
        from the above (brain board messages)

_Notes, additional info and TODOs:_
- *1  It would be better to have this in a stream with a lambda that turns on an
      individual brain by starting a Cerebrum EC2 instance

- *2  This board becomes the backlog the neurons will be tied to.  The Cerebrum
      may make changes to the messages and actually use a different queue
      but this board is the real entry-point for work to begin from a request
      from the BrainManager
- *3  The key of this file is also a unique identifier (per AWS) in its bucket
      and is based off the name of the project it is for.  That is also what
      guarantees it can be used for all other environment config and tasks
- *4  The metadata on an S3 object already contains a key:value pair called
      http://docs.aws.amazon.com/AmazonS3/latest/dev/UsingMetadata.html?shortFooter=true#object-metadata
      and
      http://docs.aws.amazon.com/AmazonS3/latest/dev/how-to-page-redirect.html?shortFooter=true
- *5  For more information of the Neurons, their workflow and some more, go do
      the Neuron repo and read the README.md