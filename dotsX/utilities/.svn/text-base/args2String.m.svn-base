function str_ = args2String(argCell)
%make an rSet()able string out of an argument list
%
%   argCell is a MATLAB- or DotsX-style list of arguments.  It should be
%   passed in as a cell array of values.  For example the cell array,
%
%   {'property1', {'on', 'off'}, 'property2', pi}
%
%   becomes the string
%
%   ','property1',{'on','off'},'property2',3.14159'
%
%   including the leading comma.
%
%   20 May 2008 BSH renamed this function makeString -> args2String
%
%   see also variable2String rSet

% Copyright 2006 by Joshua I. Gold and Benjammin S. Heasly
%   University of Pennsylvania


% loop and parse
str_ = '';

for ii = 1:2:size(argCell, 2)

    % add string field name
    str_ = [str_ ',''' argCell{ii} ''','];

    % arg is cell array
    if iscell(argCell{ii+1})

        % check for fast case--a cell array of scalars...
        a = [argCell{ii+1}{:}];
        if isnumeric(a) && length(a) == length(argCell{ii+1})
            str_ = [str_ '{' sprintf('%.5f ', a) '}'];

        else
            % do it the hard way...
            str_ = [str_, variable2String(argCell{ii+1})];
        end
    else

        % make a type-specific string
        str_ = [str_ variable2String(argCell{ii+1})];
    end
end

% add trailing parens and put it in a cell
% str_ = {['(' str_ ');']};