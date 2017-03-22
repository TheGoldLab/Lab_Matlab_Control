function rRootWrite(filename, appendFlag)
%Writes the current ROOT_STRUCT to disk.
%   rRootWrite(filename, appendFlag)
%
%   rRootWrite writes the global variable ROOT_STRUCT, used for DotsX
%   experimnet control, to disk as filename.mat.  If filename is the empty
%   [], or is not provided, a selection dialog will appear.
%
%	If appendFlag is true, ROOT_STRUCT will be added to the given file.
%	Otherwise, the given file will be overwritten.
%
%   See also rRootRead, dXwriteExisting

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

global ROOT_STRUCT

if isempty(ROOT_STRUCT)
    return
end

if nargin < 1 || isempty(filename)
    
    % save filename
    [fname,pname] = uiputfile('*.*', 'Select filename for writing');
    
    if isempty(fname)
        return
    end
    
    filename = [pname fname];
end

rs = ROOT_STRUCT;

if nargin == 2 && appendFlag
    save(filename, 'rs', '-append');
else
    save(filename, 'rs');
end

clear rs;
