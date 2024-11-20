#!/bin/bash

# A script to backup Physio Scan Archives (on vre)
# by copying to intermediate location (mrraw) and then to remote location

# ---
# Update this to your personal arrangement
REMOTE_DEST="username@remote_ip:remote_dest"
# ---

# These are standard locations on consol / vre
DIR_SRC="/data/arc/Streaming"
DIR_MRRAW_VRE="/export/research/mrraw"
DIR_MRRAW="/usr/g/mrraw"
DIR_INTER="$DIR_MRRAW/physioarchive"
DIR_INTER_VRE="$DIR_MRRAW_VRE/physioarchive"

LOG_FILE="$DIR_MRRAW/physioarchive_backup_completed.log"
TEMP_LIST="$DIR_INTER/new_files_to_backup.list"

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

# Get user input for the date to check against
read -p "Enter the date to check against (YYYYMMDD format): " check_date

# Validate the input date format
if ! [[ $check_date =~ ^[0-9]{8}$ ]]; then
    echo "Invalid date format. Please use YYYYMMDD format."
    exit 1
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

# D: Generate list of new files to backup
echo "--------------------------------------------------"
echo "Generating list of new files to backup..."
find "$DIR_INTER" -type f > "$TEMP_LIST"

# # E: Remove files from TEMP_LIST that are already in the log file (double-checking)
# if [[ -f "$LOG_FILE" ]]; then
#     grep -Fxvf "$LOG_FILE" "$TEMP_LIST" > "$TEMP_LIST.new"
#     mv "$TEMP_LIST.new" "$TEMP_LIST"
# fi

# F: Backup new files
echo "--------------------------------------------------"
echo "Backing up new files to $REMOTE_DEST..."
while IFS= read -r file; do
    rsync -ave ssh "$file" "$REMOTE_DEST"
    if [[ $? -eq 0 ]]; then
        echo "$file" >> "$LOG_FILE"
    else
        echo "Failed to rsync $file"
    fi
done < "$TEMP_LIST"

# G: Clear INTERMEDIARY
echo "--------------------------------------------------"
echo "Clearing $DIR_INTER after backup..."
rm -rf "$DIR_INTER"/*

# Cleanup
rm -f "$TEMP_LIST"

echo "Backup completed."

