% Represent a primitive array as a string.
% @param primitive a value to convert to string:
%   - logical, numeric, char, and cell may be scalar, 1D, or 2D
%   - function_handle is scalar by definition
%   - struct may only be scalar
%   .
% @param charDelimiter, optional character to substitute for single-quotes
% in string representations.
% @details
% Returns a string which represents @a primitive.  Passing the
% string to Matlab's built-in eval() should reproduce @a primitive.
% For numeric @a primitive, should be faster than num2str().  May be slow
% for cell or struct @a primitive.
% @details
% Attempts to capture the size of @a primitive by inserting commas
% and semicolons in to the string representation.  Thus, size
% representation is limited to rows and columns (2D arrays).
% @details
% Also attempts to capture the types of non-numeric arrays:
%   - char rows are quoted verbatim, with optional substitution of
%   single-quotes (helps represent nested strings).
%   - logicals are converted to the keywords "true" and "false"
%   - function_handles are converted to strings and prepended with
%   "@".  Note that function_handles are always scalar.
%   - cell array elements are converter recursively and packaged between
%   curly braces.
%   - struct fields are converted recursively and packaged in a call to the
%   struct() function.
%   .
% Numeric types are all treated as doubles--even integers are expanded to
% decimal notation.
% @details
% If @a primitive contains parentheses, ASCII "carriage return"
% (sprintf('\\r') or char(13)) or ASCII "new line" (sprintf('\\n') or
% char(10)) characters, eval() might to fail to reproduce the original @a
% primitive.
% @details
% primitiveToString() is not intended for complex types like objects.
% primitiveToString() may fail for nested of cell and struct @a primitive,
% especially when they contain char elements.
%
% @ingroup dotsUtilities
function string = primitiveToString(primitive, charDelimiter)

n = numel(primitive);
brackets = '[]';

if n == 0;
    if ischar(primitive)
        string = '['''']';
        return
    else
        string = brackets;
        return
    end
end

cols = size(primitive, 2);
if isnumeric(primitive)
    linear = sprintf('%20.10f,', primitive');
    w = 21*cols;
    linear(w:w:end) = ';';
    
elseif ischar(primitive)
    if nargin < 2
        charDelimiter = '''';
    end
    rows = n/cols;
    linear = char(charDelimiter*ones(cols+3, rows));
    linear(end,:) = ';';
    linear(2:end-2,:) = primitive';
    
elseif islogical(primitive)
    keywords = {'false', 'true '};
    asCell = keywords(1+primitive');
    linear = sprintf('%s,', asCell{:});
    w = 6*cols;
    linear(w:w:end) = ';';
    
elseif isa(primitive, 'function_handle')
    string = func2str(primitive);
    if ~strcmp(string(1), '@')
        string = sprintf('@%s', string);
    end
    return
    
elseif iscell(primitive)
    colMajor = primitive';
    asCell = cell(1,n);
    ls = zeros(1,n);
    for ii = 1:n
        s = primitiveToString(colMajor{ii});
        asCell{ii} = s;
        ls(ii) = numel(s);
    end
    linear = sprintf('%s,', asCell{:});
    seps = cumsum(ls+1);
    linear(seps(cols:cols:n)) = ';';
    brackets = '{}';
    
elseif isstruct(primitive) && isscalar(primitive)
    fn = fieldnames(primitive);
    n = length(fn);
    asCell = cell(1, 2*n);
    for ii = 1:n
        asCell{(2*ii)-1} = ['''', fn{ii}, ''''];
        asCell{(2*ii)} = primitiveToString(primitive.(fn{ii}));
    end
    args = sprintf('%s,{%s},', asCell{:});
    n = length(args);
    string = char(ones(1, n+7));
    string([1:7, n+7]) = 'struct()';
    string(8:n+6) = args(1:n-1);
    return
    
else
    string = '';
    return
    
end

n = numel(linear);
string = char(ones(1, n+1));
string(2:n+1) = linear;
string([1,n+1]) = brackets;
%string = sprintf('[%s]', linear(1:end-1));