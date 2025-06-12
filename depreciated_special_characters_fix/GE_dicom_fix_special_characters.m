function result = GE_dicom_fix_special_characters(directoryOfDicomsToCorrect, ...
                                            dicomtemplateFile, ...
                                            errorStr, ...
                                            delete_originals, ...
                                            verbose_level)
    %fix_special_characters Corrects tags in GE modified dicom files
    %   Will replace tags matching given "error string" with those from a
    %   template dicom file
    %   Use case arrises when GE ATSMs come across an umlaut in e.g.
    %   PatientName - then this tag value is replaced with "Error!"
    %
    %   Files are updated inplace (original data kept in directory:
    %   directoryOfDicomsToCorrect + "_ORIGINAL"
    %   This is intended behaviour as if no error string is found, then no
    %   update takes place. 
    %
    % Inputs:
    %   directoryOfDicomsToCorrect : A file path on system containing *.dcm
    %                                files
    %   dicomtemplateFile          : A file path to single dicom file (or
    %                                directory of dicom files) that shall 
    %                                be used to correct incorrect tags. 
    %   errorStr                   : error string to match (defualts to
    %                                "Error!" if not given
    %   delete_originals           : boolean - to delete original 
    %                                files (defaults to True)
    %   verbose_level              : Level of verbosity of output
    %                                 0 = None (Default if not given)
    %                                 1 = WARNING
    %                                 2 = INFO
    %                                 3 = DEBUG
    % Outputs:
    %   result                     : struct with fields:
    %                                   CorrectionMade:        boolean
    %                                   InputDirectory:        str
    %                                   OutputDirectory:       str
    %                                   OriginalDataDirectory: str
    %                                   OriginalDataDirectoryRemoved: boolean
    %
    % Fraser M. Callaghan 24.10.2023
    
    % MIT License
    %
    % Copyright (c) [2023] [Fraser M. Callaghan]
    % 
    % Permission is hereby granted, free of charge, to any person obtaining a copy
    % of this software and associated documentation files (the "Software"), to deal
    % in the Software without restriction, including without limitation the rights
    % to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    % copies of the Software, and to permit persons to whom the Software is
    % furnished to do so, subject to the following conditions:
    % 
    % The above copyright notice and this permission notice shall be included in all
    % copies or substantial portions of the Software.
    % 
    % THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    % IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    % FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    % AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    % LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    % OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    % SOFTWARE.

    if nargin < 3
        errorStr = "Error!";
    end

    if nargin < 4
        delete_originals = true;
    end
    
    if nargin < 5
        verbose_level = 0;
    end
    
    result = struct("CorrectionMade", false, ...
                    "InputDirectory", directoryOfDicomsToCorrect, ...
                    "OutputDirectory", directoryOfDicomsToCorrect, ...
                    "OriginalDataDirectory", "", ...
                    "OriginalDataDirectoryRemoved", false);
    
    tf = dicom_has_ERROR(directoryOfDicomsToCorrect, errorStr, verbose_level);
    if tf
        % Have found error so will move on to fixing
        if verbose_level > 1
            fprintf(1, "Fixing files in %s\n", directoryOfDicomsToCorrect);
        end
        % First move original directory to suffix _ORIGINAL then replace
        % with corrected dicoms
        directoryOfDicomsToCorrect_TEMP = directoryOfDicomsToCorrect + "_ORIGINAL";
        movefile(directoryOfDicomsToCorrect, directoryOfDicomsToCorrect_TEMP);
        directoryOut = directoryOfDicomsToCorrect;
        result.OriginalDataDirectory = directoryOfDicomsToCorrect_TEMP;
        result.CorrectionMade = true;
        
        func_fix_special_characters(directoryOfDicomsToCorrect_TEMP, dicomtemplateFile, directoryOut, errorStr, verbose_level);

        myOrigFiles = dir(fullfile(directoryOfDicomsToCorrect_TEMP,'*.dcm'));
        myNewFiles = dir(fullfile(directoryOut,'*.dcm'));
        if delete_originals
            if length(myNewFiles) == length(myOrigFiles)
                rmdir(directoryOfDicomsToCorrect_TEMP, "s")
                result.OriginalDataDirectoryRemoved = true;
            else
                if verbose_level > 0
                    fprintf(1, "WARNING: Mismatch of original and new files\n");
                    fprintf(1, "         %d != %d\n", length(myNewFileswFiles), length(myOrigFiles)); 
                    fprintf(1, "         %s not removed\n", directoryOfDicomsToCorrect_TEMP);                    
                end
            end
        end
        
        if verbose_level > 1
            fprintf(1, "Finished fixing files in %s.\n", directoryOfDicomsToCorrect_TEMP);
            fprintf(1, "  Original data in %s.\n", directoryOfDicomsToCorrect_TEMP);
            fprintf(1, "Results in %s.\n", directoryOut);
            fprintf(1, "    Written %d new files.\n", length(myNewFiles));
        end
    end
end


function true_false = does_tag_match_errorStr(iTag, errorStr)
    PNstructFields = ["FamilyName", "GivenName", "Middlename", "NamePrefix", "NameSuffix"];
    true_false = false;
    if ischar(iTag)
        if strcmp(iTag, errorStr)
            true_false = true;
            return
        end
    elseif isstruct(iTag)
        for iField = PNstructFields
            if isfield(iTag, iField)
                if strcmp(iTag.(iField), errorStr)
                    true_false = true;
                    return
                end 
            end
        end
    end
end



function true_false = dicom_has_ERROR(dcmDirectoryToCheck, errorStr, verbose)
    if nargin < 3
        verbose = 0;
    end
    % check first dicom in directory if has tag with value "Error!"
    myFiles = dir(fullfile(dcmDirectoryToCheck,'*.dcm')); 
	true_false = false;
    for k = 1:length(myFiles)
        baseFileName = myFiles(k).name;
        fullFileName = fullfile(dcmDirectoryToCheck, baseFileName);

        dMeta = dicominfo(fullFileName);
        tags = fieldnames(dMeta);
        if verbose > 1
            fprintf(1, 'Read file with %d tags\n',numel(tags))
        end
        
        for i = 1:numel(tags)
            iValue = dMeta.(tags{i});
            tagMatch_tf = does_tag_match_errorStr(iValue, errorStr);
            if tagMatch_tf
                if verbose > 1
                    fprintf(1, 'Found tag %s with value %s -- RETURNING TRUE\n', tags{i}, errorStr);
                end
                true_false = true;
                return
            end
        end
        if verbose > 2
            fprintf(1, 'Checked %d tags in %d files - RETURNING %s\n', i, k, string(true_false));
        end
        break; % for speed just check one file
    end
end


function func_fix_special_characters(dcmDirectoryToCheck, templateDicomFile, dcmOutputDirectory, errorStr, verbose)

    if nargin < 5
        verbose = 0;
    end
    
    % Check if template is folder (then take first dcm found)
    if isfolder(templateDicomFile)
        templateFiles = dir(fullfile(templateDicomFile,'*.dcm')); 
        templateBaseFileName = templateFiles(0).name;
        templateDicomFile = fullfile(templateDicomFile, templateBaseFileName);

    dMeta_orig = dicominfo(templateDicomFile);

    myFiles = dir(fullfile(dcmDirectoryToCheck,'*.dcm')); 
    c0 = 0;
    mkdir(dcmOutputDirectory);
    for k = 1:length(myFiles)
        baseFileName = myFiles(k).name;
        fullFileName = fullfile(dcmDirectoryToCheck, baseFileName);
        if verbose > 2
            fprintf(1, 'Now reading %s\n', fullFileName);
        end

        dMeta = dicominfo(fullFileName);
        dIm = dicomread(fullFileName);
        tags = fieldnames(dMeta);
        % printf('Read file with %d tags\n',numel(tags))
        fOut = fullfile(dcmOutputDirectory, baseFileName);
        for i = 1:numel(tags)
            iValue = dMeta.(tags{i});
            tagMatch_tf = does_tag_match_errorStr(iValue, errorStr);
            
            if tagMatch_tf
                dMeta.(tags{i}) = dMeta_orig.(tags{i});
                if verbose > 2
                    fprintf(1, "Replaced %s from original\n", tags{i})
                end
                % correct_tag_from_template(dMeta, dMeta_orig, tags{i});
                c0 = c0 + 1;
            end
          
        end
        dicomwrite(dIm, fOut, dMeta);
        if verbose > 2
            fprintf(1, "Written %s\n", fOut)
        end
    end

    if verbose > 1
        fprintf(1, "Updated %d new files\n", c0);    
        fprintf(1, "Done: Written %d new files\n", length(myFiles));    
    end
end



