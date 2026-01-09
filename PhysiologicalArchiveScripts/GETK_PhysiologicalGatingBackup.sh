#!/bin/bash

# ==============================================================================
# A script to backup physiological gating files
# Note these 'physiological gating files' are "OLD" format 
#   - replaced approx MR30 by PhysioArchive
#
# ------------------------------------------------------------------------------
# This is a general file - customisation for your personal/institution
# environment is achieved by loading environment variables from .env file
#
# see README.md for details
# ==============================================================================

set -euo pipefail

# --------------------------------------------------
# Resolve script directory
THIS_ROOT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"

# --------------------------------------------------
# Load environment variables
ENV_FILE="${THIS_ROOT_DIR}/.env"
if [[ -f "$ENV_FILE" ]]; then
    # shellcheck disable=SC1090
    source "$ENV_FILE"
else
    echo "ERROR: Configuration file .env not found" >&2
    exit 1
fi

# Verify required environment variables are set
: "${REMOTE_CONNECTION:?Error: REMOTE_CONNECTION must be set in .env file}"
: "${REMOTE_DESTINATION:?Error: REMOTE_DESTINATION must be set in .env file}"


# Construct remote SSH path
REMOTE_SSH="${REMOTE_CONNECTION}:${REMOTE_DESTINATION}"

# Perform rsync with error handling
echo "Backing up gating logs to ${REMOTE_SSH}..."
if rsync -avzh --inplace /usr/g/service/log/gating "${REMOTE_SSH}/"; then
    echo "Backup completed successfully"
else
    echo "Error: Backup failed" >&2
    exit 1
fi

