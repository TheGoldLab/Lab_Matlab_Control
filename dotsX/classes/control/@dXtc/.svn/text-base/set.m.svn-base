function tcs_ = set(tcs_, varargin)
%set method for class dXtc: specify property values and recompute dependencies
%   tcs_ = set(tcs_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets properties of dXtc object(s).
%-% This baby's relatively slow -- not intended
%-%   to be called within a state loop
%----------Special comments-----------------------------------------------
%
%   See also set dXtc

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% do a forced reset when the 'values' change
ii = strcmp(varargin(1:2:end), 'values');
if any(ii)
    doReset = ~isequal({tcs_.values}, varargin{2*find(ii)});
else
    doReset = false;
end

% set the fields, one at a time...
for ii = 1:2:nargin-1
    % change it
    if iscell(varargin{ii+1}) && ~isempty(varargin{ii+1})
        [tcs_.(varargin{ii})] = deal(varargin{ii+1}{:});
    else
        [tcs_.(varargin{ii})] = deal(varargin{ii+1});
    end
end

% check wether the tuning curve(s) needs recomputing
if doReset
    tcs_ = reset(tcs_, true);
end

if any(strcmp(varargin(1:2:end), 'ptr'))
    % recompute speedy pointer info

    num_vars = length(tcs_);

    for tci = 1:num_vars

        if isempty(tcs_(tci).ptr)
            tcs_(tci).ptrType  = 0;
            tcs_(tci).ptrClass = [];
            tcs_(tci).ptrIndex = [];
        else
            if isempty(tcs_(tci).ptr{2})
                tcs_(tci).ptrType = 1;
            else
                tcs_(tci).ptrType = 2;
            end
            tcs_(tci).ptrClass = tcs_(tci).ptr{1};
            tcs_(tci).ptrIndex = tcs_(tci).ptr{2};
        end
    end
end