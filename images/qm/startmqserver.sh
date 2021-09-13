#!/bin/bash

# turn on bash's job control
set -m

# Start the runmqdevserver process and put it in the background
runmqdevserver &

sleep 20

# Start the helper process
sh /root/setqmaut.sh

# now we bring the primary process back into the foreground
# and leave it there
fg %1
