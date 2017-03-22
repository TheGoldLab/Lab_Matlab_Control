function s_ = variable2String(val)
%make an eval()able string out of a variable's value
%
%   s_ will reflect the contents of val so that
%
%   eval(s_) = val
%
%   val can be a string (gets double quoted), a logical (converted to
%   'true' or 'false' keyword), a scalar (becomes %.5f), or an array
%   (becomes witespace- and semicolon-delimited series of %.5f).
%
%   20 May 2008 BSH renamed this funvtion parseVal -> variable2String

%   see also args2String eval

% Copyright 2006 by Joshua I. Gold and Benjamin S. Heasly
%   University of Pennsylvania

if ischar(val)
    s_ = ['''' val ''''];
elseif islogical(val) && val
    s_ = 'true';
elseif islogical(val)
    s_ = 'false';
elseif iscell(val)
    % Build a cell.  Build nested cells.  Build it all, baby!
    if isempty(val)
        s_ = '{}';
    else
        s_ = '{';
        for ii = 1:length(val)
            s_ = cat(2, s_, variable2String(val{ii}), ',');
        end
        s_(end) = '}';
    end
elseif isscalar(val)
    s_ = sprintf('%.5f', val);
elseif isnumeric(val) && (size(val,1) == 1 || size(val,2) == 1)

    % is the 1D numeric array long and regularly spaced?
    %   there can be rounding error, so compare diff to eps, not 0
    d = diff(val);
    if length(val) > 3 && d(1) > eps && all(abs(d-d(1))<eps)

        % use array notation shortcut
        s_ = ['[' sprintf('%.5f:%.5f:%.5f ', val(1), d(1), val(end)) ']'];

    else

        % do it the hard way
        s_ = ['[' sprintf('%.5f ', val) ']'];

    end

    % preserve column vectors
    if size(val,1) > 1
        s_ = [s_, ''''];
    end

elseif isnumeric(val) && ndims(val) == 2
    % sow ye semicolons row by row
    s_ = ['[' sprintf('%.5f ', val') ']'];
    el = find(s_ == ' ');
    ncol = size(val,2);
    s_(el(ncol:ncol:end)) = ';';
else
    s_ = '[]';
end

if length(s_) >= 2000
    error(sprintf('\n%s wants to make a string to send via matlabUDP, but it''s too long.\nmatlabUDP can send 2000 or fewer characters at time\n(for speed, last time BSH checked), but this string is %d long:\n%s', mfilename, length(s_), s_));
end