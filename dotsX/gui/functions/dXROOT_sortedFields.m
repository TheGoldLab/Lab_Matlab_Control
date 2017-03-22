function [fdnam, sep] = dXROOT_sortedFields(strct)
% function fdnam = dXROOT_sortedFields(strct)
%
% Takes any struct
%
% Returns fdnam, asorted cell array of fieldname strings in a custom order
% so that the ROOT_STRUCT menu of the dotsX gui is nice and readable.
%
% Also returns a logical array of same size as fdnam which aids in the
% placement of menu separators so that the ROOT_STRUCT menu looks awesome.
%
% 2006 by Benjamin Heasly at University of Pennsylvania

% Get real
if isempty(strct) || nargout == 0
    fdnam = {};
    sep = logical([]);
    return
end

% ROOT_STRUCT fieldnames in original order
fdnam = fieldnames(strct);

% a complete list of fdnam indices
% and a logical array of same length
n = size(fdnam,1);
leftovers = 1:n;
sep(n) = false;

% is there any sorting to do?
cNmN = isfield(strct,{'classNames','methodNames'});
if ~any(cNmN)
    % Get real.
    return
end

% pick indices of desirable fieldnames from leftovers into pickins
pickins = zeros(size(leftovers));
p = 0;

% find class-related fieldnames
desirables = {};
if cNmN(1)
    desirables = cat(2, desirables, ...
        {'classes','classNames','initNames','swapNames','noSwapNames','groups'}, ...
        strct.classNames);
end

% find method-related fieldnames
if cNmN(2)
    desirables = cat(2, desirables, ...
        {'methods','methodNames'}, ...
        strct.methodNames);
end

% strcmp-find-loop is way faster than ismember
% for picking out strings from a cell array
for desire = desirables
    idx = find(strcmp(desire,fdnam));
    if idx
        p = p+1;
        pickins(p) = idx;
        leftovers(leftovers == idx) = [];
    end
end

pickins = [pickins(1:p),leftovers];
fdnam = fdnam(pickins);

% place separator around methods fieldnames
if nargout > 1
    sep(strcmp('methods',fdnam)) = true;
    sep(p+1) = true;
end