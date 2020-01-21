function name_ = parseSnowDotsClassName(fullName, prefix)
% function name_ = parseSnowDotsClassName(fullName, prefix)

if nargin < 2 || isempty(fullName) || isempty(prefix)
   name_ = '';
   return
end

name_ = fullName(length(prefix)+1:end);