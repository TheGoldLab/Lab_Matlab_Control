function dotsMglMakeHelpDocs(overwriteExisting)
% For each dotsMgl/*.c file, make a .m with "help" documentation
%   add some boiler-plating to each .m
%   copy over the first block of comment lines

if nargin < 1
    overwriteExisting = true;
end

dirContents = dir();
nFiles = numel(dirContents);

for ii = 1:nFiles
    
    fileName = dirContents(ii).name;
    
    if ~isempty(regexp(fileName, '\.c$'))
        
        [filePath, fileBase, fileExt] = fileparts(fileName);
        mFileName = [fileBase '.m'];
        cFileName = [fileBase '.c'];
        
        if overwriteExisting ...
                || ~strcmp(which(mFileName), fullfile(pwd, mFileName))
            
            disp(sprintf('Creating %s.', mFileName));
            
            mFileID = fopen(mFileName, 'w');
            cFileID = fopen(cFileName, 'r');
            
            copyCSourceComments(mFileID, cFileID);
            fprintf(mFileID, '%%\n');
            fprintf(mFileID, '%%  2011 by Benjamin Heasly\n');
            fprintf(mFileID, '%%  "dotsMgl___()" functions are Snow Dots extensions to the mgl project.\n');
            fprintf(mFileID, '%%  For GPL license information see snow-dots/mex/dotsMgl/COPYING.\n');
            fprintf(mFileID, '%%\n');
            fprintf(mFileID, '%%  This help documentation was copied from header comments in\n');
            fprintf(mFileID, '%%  %s.\n', cFileName);
            fprintf(mFileID, '\n');
            
            fclose('all');
        end
    end
end

function copyCSourceComments(mFileID, cFileID)

% scan until a blank line, an end of comment delimiter, or end of file
line = fgetl(cFileID);
while ischar(line) && ~isempty(line) && isempty(regexp(line, '\*\/', 'ONCE'))
    matchStart = regexp(line, '\*');
    if isempty(matchStart)
        lineCopy = '';
    else
        lineCopy = line(matchStart+1:end);
    end
    fprintf(mFileID, '%% %s\n', lineCopy);
    
    line = fgetl(cFileID);
end


