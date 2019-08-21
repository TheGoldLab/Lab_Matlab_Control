function [parsedArgs, passedArgs] = parseHelperArgs(name, arglist, varargin)
% function [parsedArgs, passedArgs] = parseHelperArgs(helperName, arglist, varargin)
%
% Utility for stripping class-specific parameters from a variable-length
%  list and then consolidating the remaining ones.
%
% Arguments:
%  name is the helper class name
%  arglist is the orginal argument list to parse
%  varargin is <property name>/<default value> pairs for the class-specific parameters
%
% Returns:
%  parsedArgs is a struct of the args named in varargin found 
% Get the class-specific argument given in varargin
p = inputParser;
p.StructExpand = false;
p.KeepUnmatched = true;
p.addRequired('name');
for pp = 1:2:length(varargin)
   p.addParameter(varargin{pp}, varargin{pp+1});
end
p.parse(name, arglist{:});
parsedArgs = p.Results;

% Get remaining params, make sure the name is added
passedArgs = cat(2, ...
   'name',  p.Results.name, ...
   orderParams(p.Unmatched, arglist));