function states_ = set(states_, varargin)
%set method for class dXstate: specify property values and recompute dependencies
%   states_ = set(states_, varargin)
%
%   All DotsX classes have set methods which allow properties for one or
%   more instances to be specified, and dependent values recomputed.
%
%   Updated class instances are always returned.
%
%----------Special comments-----------------------------------------------
%-%
%-% Sets properties of an array of dXstate objects.
%-% If varargin is a single cell array argument,
%-%   then it is assumed to be an nx9 matrix
%-%   that is converted directly into the state args.
%-% Otherwise set as usual
%----------Special comments-----------------------------------------------
%
%   See also set dXstate

% Copyright 2005 by Joshua I. Gold
%   University of Pennsylvania


if nargin > 2

    % set the fields, one at a time.. no error checking
    if length(states_) == 1

        % set one object
        for ii = 1:2:nargin-1
            states_.(varargin{ii}) = varargin{ii+1};
        end

    else

        % set many objects  ... a cell means separate
        %   values given for each object; otherwise
        %   the same value is set for all objects
        inds=ones(size(states_));
        for ii = 1:2:nargin-1

            % change it
            if iscell(varargin{ii+1}) && ~isempty(varargin{ii+1})
                [states_.(varargin{ii})] = deal(varargin{ii+1}{:});
            else
                [states_.(varargin{ii})] = deal(varargin{ii+inds});
            end
        end
    end

elseif nargin == 2 && iscell(varargin{1})
    
    % cell matrix, set each state. Not using
    %   "cell2struct" because I don't think that would
    %   work here, since states_ are dXstate objects,
    %   not structs. With some error checking. Fields are:
    %   name    ... string name of state
    %   func    ... function handle, sent to feval
    %   args    ... cell array of arguments, sent to feval
    %   jump    ... string name of next state to 'jump' to
    %   wait    ... scalar time (in ms) or cell array sent to
    %                   getRandomNumber
    %   reps    ... integer number of times to repeat this state
    %   draw    ... draw flag:  0 = don't draw
    %                           1 = draw & clear buffer;
    %                           2 = draw & do NOT clear buffer
    %                           3 = draw ONCE & clear buffer
    %                           4 = draw ONCE & do NOT clear buffer
    %   query   ... flag (0=no query, 1=query), or cell array
    %                   of mappings to set
    %   cond    ... cell array conditionalization, of the form:
    %                   {'<field>', {<ptr>}, [values], {returns}; ...}
    global ROOT_STRUCT

    fn = fieldnames(states_(1));
    for ii = 1:size(varargin{1}, 1)

        for jj = 1:size(varargin{1}, 2)
            states_(ii).(fn{jj}) = varargin{1}{ii, jj};
        end

        % next name
        if ii < size(varargin{1}, 1)
            next_name = varargin{1}{ii+1, strcmp('name', fn)};
        else
            next_name = '';
        end

        % Check 'jump' field for keyword 'next'
        if strcmp(states_(ii).jump, 'next') && ...
                ii < size(varargin{1}, 1)

            states_(ii).jump = next_name;
        end

        % Check 'query' field for (cell array) mappings
        if iscell(states_(ii).query)

            states_(ii).query = checkQueryMappings(states_(ii).query);
        end
        
        % Check 'cond' field
        for kk = 1:size(states_(ii).cond, 1)

            switch states_(ii).cond{kk, 1}

                case 'jump'

                    Lnext = strcmp('next', states_(ii).cond{kk, 4});
                    if any(Lnext)
                        states_(ii).cond{kk, 4}(Lnext) = next_name;
                    end

                case 'query'

                    for ll = 1:length(states_(ii).cond{kk, 4})

                        states_(ii).cond{kk, 4}{ll} = ...
                            checkQueryMappings(states_(ii).cond{kk, 4}{ll});
                    end
            end
        end
    end
end

% Checks a cell array "query mapping", which
% is of the form:
%   {   '<class1>', {<mappings>}; ...
%       '<class2>', {<mappings>}; ...
%   }
% Here we check whether each class exists and
%   has valid objects in the active list.
function map_out_ = checkQueryMappings(map_in)

global ROOT_STRUCT

map_out_ = {}; % compile list of active helpers
for kk = 1:size(map_in, 1)

    if any(strcmp(map_in{kk, 1}, ROOT_STRUCT.classes.names)) && ...
            ~isempty(ROOT_STRUCT.(map_in{kk, 1}))

        map_out_ = cat(1, map_out_, map_in(kk, :));
    end
end

if isempty(map_out_)
    map_out_ = 1;
end
