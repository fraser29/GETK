"""Set up logger to allow import through out project
"""
import logging
import os
import shutil

### ====================================================================================================================

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s | %(levelname)s | %(name)s | %(message)s', 
                    datefmt = '%m/%d/%Y %I:%M:%S') 

def logLevelConverter(loglevel):
    if loglevel == 0:
        logging.getLogger().setLevel(logging.NOTSET)
    elif loglevel == 1:
        logging.getLogger().setLevel(logging.WARNING)
    elif loglevel == 2:
        logging.getLogger().setLevel(logging.INFO)
    elif loglevel == 3:
        logging.getLogger().setLevel(logging.DEBUG)
    logging.debug(f"Set logging level to {logging.getLevelName(logging.getLogger(__name__).getEffectiveLevel())}")


def copytree_non_shutil(src, dst):
    if not os.path.exists(dst):
        os.makedirs(dst)
    for item in os.listdir(src):
        s = os.path.join(src, item)
        d = os.path.join(dst, item)
        if os.path.isdir(s):
            copytree_non_shutil(s, d)
        else:
            shutil.copy2(s, d)
