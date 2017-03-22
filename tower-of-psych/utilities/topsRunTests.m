% Invoke Tower of Psych unit tests at or below the current folder.
% @param fileFilter optional regular expression to filter test files
% @details
% Runs unit tests for Tower of Psych.  Searches the current folder and
% subfolders for files whose names begin or end with "test" or "Test", and
% executes any Matlab xunit tests they define. If @a fileFilter is
% supplied, limits tests to those files that match @a fileFilter.
% @details
% Attempts to avoid sequential effects by invoking multiple "clear"
% statements between test files.
% @details
% If all unit tests are successful, returns true.  If any unit test fails,
% aborts and returns false.
% @details
% Here are some examples:
%   isOK = topsRunTests();
%   isFoundationOK = topsRunTests('foundation');
%
% @ingroup topsUtilities
function didPass = topsRunTests(fileFilter)
initialFolder = pwd();
tic();
close all
evalin('base', 'clear all global');
evalin('base', 'clear classes');
evalin('base', 'clear mex');

if nargin < 1
    fileFilter = '';
end
fileList = findFiles(initialFolder, fileFilter);
nFiles = numel(fileList);

disp(sprintf('\nRUNNING UNIT TESTS FROM %d FILES\n', nFiles));

didPass = true;
for ii = 1:nFiles
    
    [filePath, fileName] = fileparts(fileList{ii});
    if ~isempty(regexpi(fileName, '^test')) ...
            || ~isempty(regexpi(fileName, 'test$'))
        
        cd(filePath);
        suite = TestSuite.fromName(fileName);
        if ~isempty(suite.TestComponents)
            
            close all
            evalin('base', 'clear all global');
            evalin('base', 'clear mex');
            drawnow();
            
            disp(sprintf('\nRUNNING UNIT TESTS FROM FILE %d/%d:\n%s', ...
                ii, nFiles, fileList{ii}));
            didPass = suite.run();
        end
    end
    
    if ~didPass
        break;
    end
end

cd(initialFolder);

if didPass
    disp(sprintf('\nPASSED ALL UNIT TESTS IN %f SECONDS\n', toc()));
end