# GETK
Toolkit for working with GE MR / CT / dicoms etc

Provides hepler functions and pipelines for various tasks at console or remote. 

## Pipelines

### Fix special characters

If special characters (e.g. german umlaut) occur in a dicom tag (PatientName for instance) then ATSMs may choke and replace this tag with "Error!". 

This can lead to issues at PACs level and similar. 

This toolkit can fix these - see example code below

### Backup studies

Backup a tar.gz of a dicom study to a remote location

### Backup gating logs / phyiological gating archives

Backup gating logs / phyiological gating archives to a remote location

## Installation

This project relies on pydicom. 

This is not available in the system python on the scanner. 

It is not straight forward to make a virtual environment on the scanner and install external libraries so suggest: 
- build virtual environment on separate workstation (ie. workstation you use for EPIC) (base python should be same "semi-major" version as on scanner - e.g. 3.6.*)
- install pydicom via pip
- scp entire virtual environment onto scanner
- note - to activate virtual environment on scanner in default shell you will need source venv/bin/activate.csh (not normal source venv/bin/activate).

### To run from other python script on console

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


### To run from csh script

```tcsh
INPUT_DIRECTORY=$1

source /path/to/venv/bin/activate.csh && /path/to/venv/bin/python /path/to/GETK/GETK.py -i $INPUT_DIRECTORY -t /path/to/template/file -A FSC
# OR

EXAM=$2
SERIES=$3
source /path/to/venv/bin/activate.csh && /path/to/venv/bin/python /path/to/GETK/GETK.py -i $INPUT_DIRECTORY -exam $EXAM -series $SERIES -A FSC

```

### To run from bash script

```bash
#!/bin/bash
INPUT_DIRECTORY=$1

source /path/to/venv/bin/activate && /path/to/venv/bin/python /path/to/GETK/GETK.py -i $INPUT_DIRECTORY -t /path/to/template/file -A FSC
# OR

EXAM=$2
SERIES=$3
source /path/to/venv/bin/activate && /path/to/venv/bin/python /path/to/GETK/GETK.py -i $INPUT_DIRECTORY -exam $EXAM -series $SERIES -A FSC

```