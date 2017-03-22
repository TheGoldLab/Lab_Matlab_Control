%Invoke Snow Dots unit tests at or below the current folder.
% @param varargin optional list of parameters to affect test behavior
% @details
% Runs unit tests for Snow Dots.  Searches the current folder and
% subfolders for files whose names begin or end with "test" or "Test", and
% executes any Matlab xunit tests they define.
% @details
% @a varargin may contain parameter-value pairs which affect test
% behaviors:
%   - (... 'fileFilter', filter, ...) treats @b filter as a regular
%   expression and limits tests to those files whose names match @b filter
%   - (... 'testSetUp', function, ...) invokes @b function with feval(),
%   just before each unit test
%   - (... 'testTearDown', function, ...) invokes @b function with feval(),
%   just after each unit test
%   .
% Other arbitrary parameter-value pairs may be supplied as well.  These are
% treated as global testing data and assigned to the global struct
% DOTS_TEST_DATA.  It's up to individual unit tests to interpret the values
% contained DOTS_TEST_DATA.  For example,
%   - (... 'lookSee', delay, ...) assigns @b delay to
%   DOTS_TEST_DATA.lookSee, which some unit tests use as a hint to allow
%   time for visual inspection of graphics.
% @details
% Attempts to avoid sequential effects by invoking multiple "clear"
% statements between test files.
% @details
% If all unit tests are successful, returns true.  If any unit test fails,
% aborts and returns false.
% @details
% Here are some examples:
% @code
% everythingPassed = dotsRunTests();
% drawablesPassed = dotsRunTests('fileFilter', 'Drawable', 'lookSee', 2);
% @endcode
%
% @ingroup dotsUtilities
function didPass = dotsRunTests(varargin)
initialFolder = pwd();
tic();
close all
evalin('base', 'clear all global');
evalin('base', 'clear classes');
evalin('base', 'clear mex');

% save parameter-value pairs from varargin
LOCAL_TEST_DATA = struct( ...
    'fileFilter', '', ...
    'testSetUp', [], ...
    'testTearDown', []);
for ii = 1:2:nargin
    param = varargin{ii};
    val = varargin{ii+1};
    if isvarname(param)
        LOCAL_TEST_DATA.(param) = val;
    end
end

fileList = findFiles(initialFolder, LOCAL_TEST_DATA.fileFilter);
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
            
            global DOTS_TEST_DATA
            DOTS_TEST_DATA = LOCAL_TEST_DATA;
            
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
