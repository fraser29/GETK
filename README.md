# GETK
Toolkit for working with GE MR / CT / dicoms etc

This toolkit provides helper functions and pipelines for a variety of tasks. The code is based on real-world solutions developed to address common issues in a large institutional hospital and has been generalised for use by others.

## Disclaimer

This software is provided “AS IS”, without warranty of any kind, express or implied, including but not limited to the warranties of merchantability, fitness for a particular purpose, accuracy, reliability, or non-infringement.

The authors and contributors shall not be liable for any direct, indirect, incidental, special, exemplary, or consequential damages (including, but not limited to, loss of data, loss of profits, system failure, or personal injury) arising in any way out of the use, misuse, or inability to use this software, even if advised of the possibility of such damage.

This software is not designed, tested, or certified for use in safety-critical, medical, life-support, or mission-critical systems.

Use of this software is entirely at your own risk.

## General

The scripts and functions provided here are generalised. However, they often require user specific information (example a back up destination). In these cases, .env files are expected with the necessary information. Example files are provided for such instances. 

### .env file creation

The user should copy the .env.example file to .env and then complete the required entries with customised paths / IP addresses etc. 

### passwordless ssh 

The backup scripts rely on passwordless ssh access to a remote machine. The steps necessary for this are usually as follows:
- Copy public key to remote server: `ssh-copy-id user@remote-host`
- Test connection: `ssh user@remote-host`
- Create alias in .ssh/config e.g.: 
```bash
Host myserver
    HostName remote-host-or-ip
    User user
    IdentityFile ~/.ssh/id_ed25519
```
- Test alias: `ssh myserver`

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
- build venv on the scanner:
```bash
python3 -m venv ./myvenv
```
- on a separate machine download pydicom wheel
```bash
mkdir pydicom_wheelhouse
pip download "pydicom==2.2.2" -d pydicom_wheelhouse
```

- Transfer and install on scanner:

```bash
source ./myvenv/bin/activate.csh
pip install --no-index --find-links=/path/to/pydicom_wheelhouse pydicom==2.2.2
```
- Verify:

```bash
python -c "import pydicom; print(pydicom.__version__)"
# Should print: 2.2.2
```

---

**note** - to activate virtual environment on scanner in default shell you will need source venv/bin/activate.csh (not normal source venv/bin/activate).



## Usage

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