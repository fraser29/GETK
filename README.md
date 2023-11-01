# GETK
Toolkit for working with GE MR / CT / dicoms etc

Provides hepler functions and pipelines for various tasks at console or remote. 

## Current pipelines

### Fix special characters

If special characters (e.g. german umlaut) occur in a dicom tag (PatientName for instance) then ATSMs choke nad replace this tag with "Error!". 

This can lead to issues at PACs level and similar. 

This toolkit can fix these - see example code below

#### Pipeline:

- Check input directory if the error string ("Error!") exists
- If False - do nothing
- If True:
- Make a temporary directory
- Loop over all dicoms in input directory 
  - Loop over each Tag
  - If tag contains error string
    - replace using value from tag of template dicom file


## On console

This project relies on pydicom. 

This is not available in the system python on the scanner. 

It is not straight forward to make a virtual environment on the scanner and install external libraries so suggest: 
- build virtual environment on separate workstation (ie. workstation you use for EPIC) (base python should be same "semi-major" version as on scanner - e.g. 3.6.*)
- install pydicom via pip
- scp entire virtual environment onto scanner
- note - to activate virtual environment on scanner you will need source venv/bin/activate.csh (not normal source venv/bin/activate).

## To run from other python script on console

This can be called from a python script that is running in the system environment and will use the GETK python environment  

```python

venvSource = "/path/to/virtualenv/bin/activate"
# Example to fix special characters
cmd = f"/path/to/venv/bin/python /path/to/GETK/GETK.py -i '{origDir}' -t '{templateDir}' -A FSC"

runStr = f"source {venvSource} && {cmd}"
p1 = subprocess.Popen(runStr, stdout=subprocess.PIPE, stderr=subprocess.PIPE, shell=True, executable='/bin/bash')
p1.wait()
# Optional
stdout, stderr = p1.communicate()
print(p1.returncode, stdout, stderr)
```


## To run from bash script

# TODO - want to run from passing Ex + Series

```bash
source /path/to/venv/bin/activate.csh && /path/to/venv/bin/python /path/to/GETK/GETK.py -i /path/to/dicom/directory -t /path/to/template/file -A FSC

```