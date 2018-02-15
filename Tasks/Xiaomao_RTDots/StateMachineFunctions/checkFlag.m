function string = checkFlag(state,flag,options)
% string = checkFlag(state,flag,options)
% 
% Checks the boolean in 'state' indicated by the 'flag' parameter. If true,
% return the first value in options, else return the second value.
%
% Inputs:
%   state    -  topsGroupList object that contains information and parameters
%               regarding (but not limited to) the current trial
%   flag     -  string indicating which boolean in state to check
%   options  -  cell array with containing 2 strings
%
% Outputs:
%   string   -  either the first string in options, or the second
%
% 10/2/17    xd  wrote it

%% Check the flag
toCheck = state{'Flag'}{flag};
if toCheck
    string = options{1};
else 
    string = options{2};
end

end

