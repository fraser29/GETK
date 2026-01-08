#!/bin/bash

# ==============================================================================
# A script to backup Physio Scan Archives (on vre)
# by copying to intermediate location (mrraw) and then to remote location
#
# Pass in a date to check against (YYYYMMDD), or it will prompt for one
#
# ------------------------------------------------------------------------------
# This is a general file - customisation for your personal/institution
# environment is achieved by loading environment variables from .env file
#
# see README.md for details
# ==============================================================================

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

REMOTE_SSH="$REMOTE_CONNECTION:$REMOTE_DESTINATION"
# ---

# These are standard locations on consol / vre
DIR_SRC="/data/arc/Streaming"
DIR_MRRAW_VRE="/export/research/mrraw"
DIR_MRRAW="/usr/g/mrraw"
DIR_INTER="$DIR_MRRAW/physioarchive"
mkdir -p $DIR_INTER
DIR_INTER_VRE="$DIR_MRRAW_VRE/physioarchive"

TEMP_LIST="$DIR_INTER/new_files_to_backup.list"

timestamp=$(date +"%Y%m%d_%H%M%S")
LOG_FILE="$DIR_MRRAW/physioarchive_backup_completed_$timestamp.log"
touch "$LOG_FILE"

## --- INITIATION COMPLETE --- ##

# Test the connection
if ssh $REMOTE_CONNECTION "[ -d $REMOTE_DESTINATION ]"; then
    echo "CONNECTION OK" >> $LOG_FILE
else
    echo "CONNECTION TO $REMOTE_SSH FAILED - EXITING " >> $LOG_FILE
    exit 1
fi


# Function to check if file date is later than given date
is_file_date_later() {
    local filename="$1"
    local compare_date="$2"
    
    # Extract date from filename (assuming format YYYYMMDD)
    file_date=$(echo "$filename" | grep -oE '[0-9]{8}')
    
    # Check if a valid date was found in the filename
    if [[ -z "$file_date" ]]; then
        return 1  # False: No valid date found in filename
    fi
    
    # Compare dates
    if [[ "$file_date" > "$compare_date" ]]; then
        return 0  # True: File date is later
    else
        return 1  # False: File date is not later
    fi
}

# Function to validate date format
validate_date() {
    local input_date="$1"
    if ! [[ $input_date =~ ^[0-9]{8}$ ]]; then
        return 1
    fi
    return 0
}

# Get the date either from command line argument or user input
check_date=""
if [ $# -eq 1 ]; then
    if validate_date "$1"; then
        check_date="$1"
    else
        echo "Invalid date format in argument. Please use YYYYMMDD format."
        exit 1
    fi
else
    # Get user input for the date to check against
    while true; do
        read -p "Enter the date to check against (YYYYMMDD format): " check_date
        if validate_date "$check_date"; then
            break
        else
            echo "Invalid date format. Please use YYYYMMDD format."
        fi
    done
fi

# A: Copy files to intermediary
# Ensure intermediary is empty at the start
echo "--------------------------------------------------"
echo "Clearing $DIR_INTER..."
rm -rf "$DIR_INTER"/*
mkdir -p "$DIR_INTER"

# B: Generate list of files to copy to intermediary
ssh vre find "$DIR_SRC" -type f > "$TEMP_LIST"

# Remove files from TEMP_LIST that are not later than the check_date
echo "Filtering files newer than $check_date..."
temp_file=$(mktemp)
while IFS= read -r file; do
    if is_file_date_later "$(basename "$file")" "$check_date"; then
        echo "$file" >> "$temp_file"
    fi
done < "$TEMP_LIST"
mv "$temp_file" "$TEMP_LIST"

# C: Copy new files to intermediary
echo "--------------------------------------------------"
echo "Copying new files from $DIR_SRC to $DIR_INTER..."
while IFS= read -r file; do
    # Get relative path of the file
    rel_path="${file#$DIR_SRC/}"
    # Create necessary directories in INTERMEDIARY
    mkdir -p "$DIR_INTER/$(dirname "$rel_path")"
    # Copy the file
    echo "Copy $file --> $DIR_INTER_VRE/$rel_path "
    ssh -n vre cp "$file" "$DIR_INTER_VRE/$rel_path"
done < "$TEMP_LIST"


# F: Backup new files
echo "--------------------------------------------------"
echo "Backing up new files to $REMOTE_SSH..."
rsync -ave ssh "$DIR_INTER" "$REMOTE_SSH"

# G: Clear INTERMEDIARY
echo "--------------------------------------------------"
echo "Clearing $DIR_INTER after backup..."
rm -rf "$DIR_INTER"/*

echo "Backup completed."

