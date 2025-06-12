
import os
import argparse
import GE_dicom_TK

from GETK_helper import logging, logLevelConverter

### ====================================================================================================================


##  ========= RUN ACTIONS =========
def runActions(args):

    ####
    logLevelConverter(args.LOG_LEVEL)
    if args.ACTION == 'FSC':
        if args.templatePath is None:
            args.templatePath = GE_dicom_TK.getImagePaths(args.exam, args.series)[0]
        res = GE_dicom_TK.GE_fix_special_characters_error(directoryDicomFilesToCorrect=args.inputPath,
                                                            dcmTemplateFile=args.templatePath,
                                                            DELETE_ORIGINALS=True)
        logging.info(f"Corrections made: {res[0]}.")
        logging.info(f"Results are at: {res[1]}.")
        ##



### ====================================================================================================================
### ====================================================================================================================
# S T A R T
#
if __name__ == '__main__':
    # --------------------------------------------------------------------------
    #  ARGUMENT PARSING
    # --------------------------------------------------------------------------

    actions_doc = """    FSC = Fix special characters error (requires -i and [-t] or [-exam and -series] options)"""

    ap = argparse.ArgumentParser(description='Simple Python GE Toolkit - GETK')

    ap.add_argument('-i', dest='inputPath', help='Path to find dicoms (file or directory or tar or tar.gz or zip)', type=str, default=None)
    ap.add_argument('-o', dest='outputFolder', help='Path for output - if set then will organise dicoms into this folder', type=str, default=None)
    ap.add_argument('-t', dest='templatePath', help='Path to template file', type=str, default=None)
    ap.add_argument('-exam', dest='exam', help='Exam number', type=int, default=None)
    ap.add_argument('-series', dest='series', help='Series number', type=int, default=None)

    ap.add_argument('-A', dest='ACTION', help='Action to execute: \n%s'%(actions_doc), type=str, required=True)
    # -- program behaviour guidence -- #
    ap.add_argument('-LOG', dest='LOG_LEVEL', help='Loglevel: 0=None, 1=WARNINGS, 2=INFO, 3=DEBUG', type=int)
    ##

    arguments = ap.parse_args()
    if arguments.inputPath is not None:
        arguments.inputPath = os.path.abspath(arguments.inputPath)
    if arguments.outputFolder is not None:
        arguments.outputFolder = os.path.abspath(arguments.outputFolder)
    ## -------------

    runActions(arguments)