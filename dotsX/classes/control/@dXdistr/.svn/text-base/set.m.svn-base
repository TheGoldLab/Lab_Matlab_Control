function d_ = set(d_, varargin)
%set method for class dXdistr: specify property values and recompute dependencies
%   d_ = set(d_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets properties of dXdistr object(s).
%----------Special comments-----------------------------------------------
%
%   See also set dXdistr

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% set the fields, one at a time...
for ii = 1:2:nargin-1
    % change it
    if iscell(varargin{ii+1}) && ~isempty(varargin{ii+1})
        [d_.(varargin{ii})] = deal(varargin{ii+1}{:});
    else
        [d_.(varargin{ii})] = deal(varargin{ii+1});
    end
end

num_vars = length(d_);
for di = 1:num_vars

    % recompute speedy pointer info
    if isempty(d_(di).ptr)
        d_(di).ptrType  = 0;
        d_(di).ptrClass = [];
        d_(di).ptrIndex = [];
    else
        if isempty(d_(di).ptr{2})
            d_(di).ptrType = 1;
        else
            d_(di).ptrType = 2;
        end
        d_(di).ptrClass = d_(di).ptr{1};
        d_(di).ptrIndex = d_(di).ptr{2};
    end
end

% pick two new values (value and nextValue)
%   don't double-trigger the "subBlockMethod", 
%   which happens when subBlockTrial = 0.
d_ = endTrial(d_, false, {'setMethod'});
d_.subBlockTrial = nan;
d_ = endTrial(d_, false, {'setMethod'});
d_.subBlockTrial = 0;