#!/bin/bash

# A script to backup physiological gating files
# Note this is "OLD" format - changed approx MR30

# ------ 
# PERSONALISE THIS FOR YOUR SETUP
REMOTE_DEST=username@remote_ip:remote_dest
#-------

rsync -avzhe ssh /usr/g/service/log/gating $REMOTE_DEST



