#!/usr/bin/env python3

# ==============================================================================
# Author: Fraser Callaghan
# Description: Backs up studies from scanner for clinical backup
# Last Update: 03.10.2022
#
# INPUT: see argparse
# ACTION:  
#       - loop through exam IDs 
#       - check if already backed up 
#       - run backupStudy.sh 
#       - stop once done enough.
#
# ------------------------------------------------------------------------------
# This is a general file - customisation for your personal/institution
# environment is achieved by loading environment variables from .env file
#
# see README.md for details
# ==============================================================================

import os
import sys
import argparse
import logging
import datetime

def load_env_file(env_path):
    """Load environment variables from a file"""
    if not os.path.exists(env_path):
        raise FileNotFoundError(f"Missing env file: {env_path}")
    
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
LOG_DIR = os.environ.get('LOG_DIR', '/usr/g/mrraw/LOGS/MRStudyBackup')
BACKUP_HOST = os.environ.get('BACKUP_HOST', None)
SCP_BACKUP_DESTINATION = os.environ.get('SCP_BACKUP_DESTINATION', None)

COMPLETE_DIR = os.path.join(thisDir, 'COMPLETE')
backupStudyScript = os.path.join(thisDir, 'backupStudy.sh')
logFileName = os.path.join(LOG_DIR, f'backupAll_{datetime.datetime.now().strftime("%Y%m%d-%H%M%S")}.log')

if not os.path.isfile(backupStudyScript):
    print(f"Missing bash script - expect to find {backupStudyScript}")
    sys.exit()


if (BACKUP_HOST is None) or (SCP_BACKUP_DESTINATION is None):
    print("## ERROR parsing .env file - missing arguments")
    print("  Expect: BACKUP_HOST & SCP_BACKUP_DESTINATION")
    sys.exit()

consolID = os.uname()[1]
os.makedirs(COMPLETE_DIR, exist_ok=True)
os.makedirs(LOG_DIR, exist_ok=True)
COMPLETE_FILE = os.path.join(thisDir, f'LAST_SUCCESSFUL_EXAMID_{consolID}')
# ===============================================================================

#
def __initLogging():
    print(f"Building log file: {logFileName}")
    logging.basicConfig(filename=logFileName,
                        format='%(asctime)s | %(levelname)-8s | %(message)s',
                        datefmt='%d/%m/%Y %I:%M:%S %p',
                        level=logging.DEBUG)


def sendCompleteFile(successID):
    with open(COMPLETE_FILE, 'a') as fid:
        fid.write(f'Complete on {datetime.datetime.now()} with last success: {successID}\n')
    exeStr = f'scp {COMPLETE_FILE} "{BACKUP_HOST}:{SCP_BACKUP_DESTINATION}/"'
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
    if lastSuccess is not None:
        sendCompleteFile(lastSuccess)
    else: 
        logging.error(f"No successful backups made")


def get_last_success_id():
    if not os.path.isfile(COMPLETE_FILE):
        return 0
    with open(COMPLETE_FILE, 'r') as fid:
        last_line = fid.readlines()[-1]
        return int(last_line.split(' ')[-1])


def run_from_args(arguments):
    if arguments.nStart is None:
        arguments.nStart = get_last_success_id()
    startID = int(arguments.nStart)
    run(startID, arguments.nDelta, arguments.nFail)



### ====================================================================================================================
### ====================================================================================================================
# S T A R T
if __name__ == '__main__':

    # --------------------------------------------------------------------------
    #  ARGUMENT PARSING
    # --------------------------------------------------------------------------
    ap = argparse.ArgumentParser(description='MRI scanner backup')

    ap.add_argument('-nStart', dest='nStart', help='Exam ID to start from (default get from COMPLETE file)', type=int, default=None)
    ap.add_argument('-nDelta', dest='nDelta', help='Number of exam IDs to check (count from start). [99]', type=int, default=99)
    ap.add_argument('-nFail', dest='nFail', help='Number of failures (not found) before quit. [55]', type=int, default=15)

    args = ap.parse_args()

    run_from_args(args)





