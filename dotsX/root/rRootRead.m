function rRootRead(filename)
%Loads a DotsX ROOT_STRUCT variable from disk into the global workspace
%   rRootRead(filename)
%
%   rRootRead loads the global variable ROOT_STRUCT, used for DotsX
%   experimnet control, from filename.mat.  If filename is the empty [], or
%   is not provided, a selection dialog will appear.
%
%   If filename.mat contains a ROOT_STRUCT variable, any existing
%   ROOT_STRUCT will be overwritten.
%
%   See also rRootWrite, dXwriteExisting

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

if nargin < 1 || isempty(filename)
    
    % get filename
    [fname, pname] = uigetfile({'*.mat', 'data files'; ...
        '*.*',  'All Files (*.*)'}, 'Pick a ROOT_STRUCT file');

    if isempty(fname)
        return
    end

    filename = [pname fname];
end

% check for 'rs' variable
a = whos('-file', filename);
if length(a) == 1 && strcmp(a.name, 'rs')    
    load(filename);
    ROOT_STRUCT = rs;
end

% call root methods to init -- explicitly give it
%   the root classes in *reverse* order, FIFO
if any(strcmp(ROOT_STRUCT.methods.names, 'root'))
    rBatch('blank', ROOT_STRUCT.methods.blank(end:-1:1));
end
