function bk_ = set(bk_, varargin)
%set method for class dXblank: specify property values and recompute dependencies
%   bk_ = set(bk_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets properties of dXblank object(s)
%----------Special comments-----------------------------------------------
%
%   See also set dXblank

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania

% set the fields, one at a time...
for i = 1:2:nargin-1

    % change it
    if iscell(varargin{i+1})
        [bk_.(varargin{i})] = deal(varargin{i+1}{:});
    else
        [bk_.(varargin{i})] = deal(varargin{i+1});
    end    
end
