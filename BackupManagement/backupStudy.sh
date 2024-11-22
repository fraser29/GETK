#!/bin/bash

# ==========================================================================
# Author: Fraser Callaghan
# Description: Backs up studies from scanner for clinical backup
# Last Update: 18.11.2024
#
# INPUT: exam number
# ACTION: get exam dicoms via pathExtract -> tar.gz -> scp to remote destination -> mv pathExtract output text file to COMPLETE directory
#

# Load environment variables
ENV_FILE="$(dirname "${BASH_SOURCE[0]}")/.env"
if [ -f "$ENV_FILE" ]; then
    source "$ENV_FILE"
else
    echo "#ERROR: Configuration file .env not found"
    exit 1
fi

# Ensure required variables are set
if [ -z "$SCP_BACKUP_DESTINATION" ]; then
    echo "#ERROR: SCP_BACKUP_DESTINATION not set in .env file"
    exit 1
fi
if [ -z "$BACKUP_HOST" ]; then
    echo "#ERROR: BACKUP_HOST not set in .env file"
    exit 1
fi

# ==========================================================================
PREFIX=$(uname -n)

## CHECK INPUTS
if [ -z "$1" ]; then
  echo "#ERROR: give exam number"
  exit 1
fi

pathExtract_exe="/usr/g/service/cclass/pathExtract"
if [ ! -f "$pathExtract_exe" ]; then
    echo "#ERROR: can not find pathExtract exe : $pathExtract_exe"
    exit 1
fi

# Check if the host is reachable - leave this to user
# if ssh -q "$BACKUP_HOST" exit; then
#     # Check if the destination exists on the host
#     if ! ssh "$BACKUP_HOST" "[ -e \"$SCP_BACKUP_DESTINATION\" ]"; then
#         echo "Destination '$SCP_BACKUP_DESTINATION' does not exist on host '$BACKUP_HOST'."
#         exit 1
#     fi
# else
#     echo "Host '$BACKUP_HOST' is not reachable."
#     exit 1
# fi

# ==========================================================================
## RUN PATEXTRACT
# ROOT="/export/home1/BackupManagement_FC"
ROOT=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
COMPLETE_DIR="${ROOT}/COMPLETE"
mkdir -p $COMPLETE_DIR

TXT_FILE="${ROOT}/${PREFIX}_ex${1}.txt"
TAR_FILE="${ROOT}/${PREFIX}_ex${1}.tar.gz"

# Read image file paths from DB to txt file
$pathExtract_exe "$1" > "${TXT_FILE}"

## CHECK OUTPUT TO ENSURE EXAM EXISTS
# Check first line (in case exam not exist
firstline=$(head -n 1 "${TXT_FILE}")

# If exam not exist then clean up and exit
if [[ "$firstline" != *"EXAM PATH"* ]]; then
  # IS POSSIBLE THAT SOME LOG INFO IN FIRST LINE SO REMOVE AND TRY AGAIN
  sed -i '1d' "${TXT_FILE}"
  firstline2=$(head -n 1 "${TXT_FILE}")
  if [[ "$firstline2" != *"EXAM PATH"* ]]; then
    sed -i '1d' "${TXT_FILE}"
    firstline3=$(head -n 1 "${TXT_FILE}")
    if [[ "$firstline3" != *"EXAM PATH"* ]]; then
      echo "exam ${1} not exist - FIRSTLINE=${firstline}"
      echo "    FIRSTLINE2=${firstline2}"
      echo "    FIRSTLINE3=${firstline3}"
      # echo "clean up"
      rm -rf "${TXT_FILE}"
      exit 1
    fi
  fi
fi

# Remove first line for tar command
sed -i '1d' "${TXT_FILE}"

# Tar up study
tar zcf "${TAR_FILE}" -T "${TXT_FILE}"

# Copy study to FC workstation
# Further processing happens here (archive to MRI-Data)
scp "${TAR_FILE}" $BACKUP_HOST:$SCP_BACKUP_DESTINATION

# Clean up.
mv "${TXT_FILE}" $COMPLETE_DIR

rm -rf "${TAR_FILE}"

exit 0


