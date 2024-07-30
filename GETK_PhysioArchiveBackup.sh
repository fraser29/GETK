#!/bin/bash

# TODO - need to account for action on vre run by ssh - not done yet

# A script to backup Physio Scan Archives (on vre) 
# by copying to intermediate location (mrraw) and then to remote location

# ---
# Update this to your personal arrangement
REMOTE_DEST="user@remote:/path/to/backup"
# ---

# These are standard locations on consol / vre
DIR_SRC="/data/arc/Streaming"
DIR_MRRAW_VRE="/export/research/mrraw"
DIR_MRRAW="/usr/g/mrraw"
DIR_INTER="$DIR_MRRAW/physioarchive"
DIR_INTER_VRE="$DIR_MRRAW_VRE/physioarchive"

LOG_FILE="$DIR_MRRAW/physioarchive_backup_completed.log"
TEMP_LIST="$DIR_INTER/new_files_to_backup.list"

# A: Copy files to intermediary
# Ensure intermediary is empty at the start
echo "Clearing $DIR_INTER..."
rm -rf "$DIR_INTER"/*
mkdir -p "$DIR_INTER"

# B: Generate list of files to copy to intermediary
ssh vre find "$DIR_SRC" -type f > "$TEMP_LIST"

# Remove files from TEMP_LIST that are already in the log file
if [[ -f "$LOG_FILE" ]]; then
    grep -Fxvf "$LOG_FILE" "$TEMP_LIST" > "$TEMP_LIST.new"
    mv "$TEMP_LIST.new" "$TEMP_LIST"
fi

# C: Copy new files to intermediary
echo "Copying new files from $DIR_SRC to $DIR_INTER..."
while IFS= read -r file; do
    # Get relative path of the file
    rel_path="${file#$DIR_SRC/}"
    # Create necessary directories in INTERMEDIARY
    mkdir -p "$DIR_INTER/$(dirname "$rel_path")"
    # Copy the file
    cp "$file" "$DIR_INTER_VRE/$rel_path"
done < "$TEMP_LIST"

# D: Generate list of new files to backup
echo "Generating list of new files to backup..."
find "$DIR_INTER" -type f > "$TEMP_LIST"

# E: Remove files from TEMP_LIST that are already in the log file (double-checking)
if [[ -f "$LOG_FILE" ]]; then
    grep -Fxvf "$LOG_FILE" "$TEMP_LIST" > "$TEMP_LIST.new"
    mv "$TEMP_LIST.new" "$TEMP_LIST"
fi

# F: Backup new files
echo "Backipg up new files to $REMOTE_DEST..."
while IFS= read -r file; do
    rsync -av "$file" "$REMOTE_DEST"
    if [[ $? -eq 0 ]]; then
        echo "$file" >> "$LOG_FILE"
    else
        echo "Failed to rsync $file"
    fi
done < "$TEMP_LIST"

# G: Clear INTERMEDIARY
echo "Clearing $DIR_INTER after backup..."
rm -rf "$DIR_INTER"/*

# Cleanup
rm -f "$TEMP_LIST"

echo "Backup completed."
