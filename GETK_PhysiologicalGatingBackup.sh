#!/bin/bash

# A script to backup physiological gating files
# Note this is "OLD" format - changed approx MR30

if [ -f .env ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Verify required environment variables are set
if [ -z "$REMOTE_CONNECTION" ] || [ -z "$REMOTE_DESTINATION" ]; then
    echo "Error: REMOTE_CONNECTION and REMOTE_DESTINATION must be set in .env file"
    exit 1
fi

# ------ 
REMOTE_SSH="$REMOTE_CONNECTION:$REMOTE_DESTINATION"
#-------

rsync -avzhe ssh /usr/g/service/log/gating $REMOTE_SSH



