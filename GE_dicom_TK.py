"""
Collection of tools for working with GE dicom files
"""

import os
import shutil
import pydicom as dicom

from GETK_helper import logging

def GE_fix_special_characters_error(directoryDicomFilesToCorrect, 
                                    dcmTemplateFile,
                                    errorStr="Error!",
                                    DELETE_ORIGINALS=True):
    """Fix dicom tag errors due to special characters (umlauts etc)

    Args:
        directoryDicomFilesToCorrect (str): Path to directory of dicoms to be corrected
        dcmTemplateFile (str)             : Full path to dicom file to be used for tag replacement (may be a directroy containing file)
        errorStr (str, optional)          : error string to look for. Defaults to "Error!".
        DELETE_ORIGINALS (bool, optional) : To delete original dicom files (if False, they are kept in directoryDicomFilesToCorrect+"_ORIGINAL"). Defaults to True.
    
    Returns:
        bool : True if correction made
        str  : path to directory containing corrected dicom files
    """

    if not os.path.isdir(directoryDicomFilesToCorrect):
        raise FileNotFoundError(f"Directory to convert does not exist: {directoryDicomFilesToCorrect}")
    
    if os.path.isdir(dcmTemplateFile):
        dcmTemplateFile = findFirstDicom(dcmTemplateFile) 
    if (dcmTemplateFile is None) or (not os.path.isfile(dcmTemplateFile)):
        raise FileNotFoundError(f"{dcmTemplateFile} not found")
    
    firstDicom = findFirstDicom(directoryDicomFilesToCorrect)
    dcmHasErrorStr = doesDicomHaveAnyTagContainingStr(firstDicom, errorStr)
    logging.debug(f"Checked file {firstDicom} has '{errorStr}' : {dcmHasErrorStr}.")
    if not dcmHasErrorStr:
        logging.info(f"No corrections made as '{errorStr}' not found in any tags.")
        return False, directoryDicomFilesToCorrect
    #
    # If here then need to proceed with performing corrections
    #
    # Build temporary working environment
    directoryDicomFilesToCorrect_TEMP = directoryDicomFilesToCorrect+"_ORIGINAL"
    shutil.move(directoryDicomFilesToCorrect, directoryDicomFilesToCorrect_TEMP)
    os.mkdir(directoryDicomFilesToCorrect)
    logging.debug(f"Moved originals to {directoryDicomFilesToCorrect_TEMP}.")
    #
    # Correct TAGs in all files
    dcmTemplateFile_ds = dicom.read_file(dcmTemplateFile, stop_before_pixels=True)
    for iFile in os.listdir(directoryDicomFilesToCorrect_TEMP):
        iDcm_ds = replaceTagsMatchingStr_withTemplate(os.path.join(directoryDicomFilesToCorrect_TEMP, iFile), errorStr, dcmTemplateFile_ds)
        newName = os.path.join(directoryDicomFilesToCorrect, iFile)
        iDcm_ds.save_as(newName)
    if DELETE_ORIGINALS:
        shutil.rmtree(directoryDicomFilesToCorrect_TEMP)
        logging.debug(f"Deleted originals at {directoryDicomFilesToCorrect_TEMP}.")
    return True, directoryDicomFilesToCorrect



def replaceTagsMatchingStr_withTemplate(dcmFile, tagMatchStr, template_dcm):
    """Replace tags that match given string with tags from template

    Args:
        dcmFile (str): dicom file to replace tags in
        tagMatchStr (str): tag value to search for a match
        template_dcm (str or pydicom.dataset): the template dicom

    Returns:
        pydicom.dataset: the dicom datset (pydicom.read_file(dcmFile)) with tags replaced
    """
    if type(template_dcm) is str:
        template_dcm = dicom.read_file(template_dcm, stop_before_pixels=True)
    dcm_ds = dicom.read_file(dcmFile)
    for element in dcm_ds:
        if _doesTagContainSearchStr(element, tagMatchStr):
            logging.debug(f"Correcting {element.tag} in {dcmFile}")
            dcm_ds[element.tag].value = template_dcm[element.tag].value
    return dcm_ds


def _doesTagContainSearchStr(element, searchStr):
    eleType = type(element.value)
    if eleType == dicom.sequence.Sequence or \
        eleType == list or \
        eleType == dicom.multival.MultiValue:
        for i in element.value:
            if searchStr in str(i):
                return True
    else:
        if searchStr in str(element.value):
            return True
    return False


def doesDicomHaveAnyTagContainingStr(dicomFile, searchStr):
    """Check all tags in dicom file retrun True if any contains searchStr in value

    Args:
        dicomFile (str): full path to dicom file
        searchStr (str): string to search within tags

    Returns:
        bool: True if search string is found
    """
    try:
        ds = dicom.read_file(dicomFile, stop_before_pixels=True)
    except dicom.filereader.InvalidDicomError:
        return False
    for element in ds:
        res = _doesTagContainSearchStr(element, searchStr)
        if res:
            return True
    return False


def findFirstDicom(rootDir):
    """Search recursively for first dicom file under root and return.

    Args:
        rootDir (str): directory on filesystem

    Returns:
        str: filename of first dicom found (None if none found)
    """
    for root, _, files in os.walk(rootDir):
        for iFile in files:
            if 'dicomdir' in iFile.lower():
                continue
            thisFile = os.path.join(root, iFile)
            try:
                dicom.read_file(thisFile, stop_before_pixels=True) # Read file to ensure is a dicom file
                return thisFile
            except dicom.filereader.InvalidDicomError:
                continue
    return None     
