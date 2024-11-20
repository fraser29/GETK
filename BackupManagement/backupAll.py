#!/usr/bin/env python3

# ==========================================================================
# Author: Fraser Callaghan
# Description: Backs up studies from scanner for clinical backup
# Last Update: 03.10.2022
#
# INPUT: see argparse
# ACTION: loop through exam IDs - check if already backedup - run backupStudy.sh - stop once done enough.
#

# ==========================================================================

import os
import argparse
import logging
import datetime

def load_env_file(env_path):
    """Load environment variables from a file"""
    if not os.path.exists(env_path):
        return
    
    with open(env_path) as f:
        for line in f:
            line = line.strip()
            if line and not line.startswith('#'):
                key, value = line.split('=', 1)
                os.environ[key.strip()] = value.strip()

# --------CONSTANTS--------------------------------------------------------------
thisDir = os.path.dirname(os.path.realpath(__file__))
load_env_file(os.path.join(thisDir, '.env'))  # Load environment variables

# Read environment variables with defaults
LOG_DIR = os.environ.get('LOG_DIR', '/usr/g/mrraw/kispi_logs/MRStudyBackup')
DEST_ARCHIVE_DIR = os.environ.get('DEST_ARCHIVE_DIR', 'eiger:/DATA/DATA/CLINICAL_ARCHIVE/')

StartExamIDf = os.path.join(thisDir, 'StartExamID.txt')
COMPLETE_DIR = os.path.join(thisDir, 'COMPLETE')
backupStudyScript = os.path.join(thisDir, 'backupStudy.sh')
logFileName = os.path.join(LOG_DIR, f'backupAll_{datetime.datetime.now().strftime("%Y%m%d-%H%M%S")}.log')

consolID = os.uname()[1]
COMPLETE_FILE = os.path.join(thisDir, f'LAST_SUCCESSFUL_EXAMID_{consolID}')
# ===============================================================================

#
def __initLogging():
    logging.basicConfig(filename=logFileName,
                        format='%(asctime)s | %(levelname)-8s | %(message)s',
                        datefmt='%d/%m/%Y %I:%M:%S %p',
                        level=logging.DEBUG)

def sendCompleteFile(successID):
    with open(COMPLETE_FILE, 'a') as fid:
        fid.write(f'Complete on {datetime.datetime.now()} with last success: {successID}\n')
    exeStr = f'scp {COMPLETE_FILE} "{DEST_ARCHIVE_DIR}"'
    logging.info(f'RUN : {exeStr}')
    os.system(exeStr)
    logging.info(f'{40*"="} DONE {40*"="}')

def run(ID_start, N_delta, max_fail):
    __initLogging()
    logging.info(f'Begin from {ID_start} to {ID_start+N_delta} (max fail = {max_fail}) on {consolID} ')
    nFail = 0
    lastSuccess = None
    for k1 in range(ID_start, ID_start+N_delta):
        completeFile = os.path.join(COMPLETE_DIR, f'{consolID}_ex{k1}.txt')
        if not os.path.isfile(completeFile):
            exeStr = f'{backupStudyScript} {k1}'
            logging.info(f'RUN : {exeStr}')
            os.system(exeStr)

        if not os.path.isfile(completeFile):
            logging.error(f'{k1} failed. ')
            nFail += 1
        else:
            lastSuccess = k1

        if nFail >= max_fail:
            logging.warning(f'{nFail} have failed. Exiting')
            break

    sendCompleteFile(lastSuccess)


def run_from_args(arguments):
    startID = int(arguments.nStart)
    run(startID, arguments.nDelta, arguments.nFail)



### ====================================================================================================================
### ====================================================================================================================
# S T A R T
if __name__ == '__main__':

    # --------------------------------------------------------------------------
    #  ARGUMENT PARSING
    # --------------------------------------------------------------------------
    ap = argparse.ArgumentParser(description='KISPI scanner backup')

    ap.add_argument('-nStart', dest='nStart', help='Exam ID to start from', type=int, required=True)
    ap.add_argument('-nDelta', dest='nDelta', help='Number of exam IDs to check (count from start). [9999]', type=int, default=9999)
    ap.add_argument('-nFail', dest='nFail', help='Number of failures (not found) before quit. [555]', type=int, default=555)

    args = ap.parse_args()

    run_from_args(args)





