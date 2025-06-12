"""Set up logger to allow import through out project
"""
import logging

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