function cellStr = makeCellString(cellStr)
% function cellStr = makeCellString(cellStr)
%
% Utility to make sure the input is a row-wise cell array of strings

if ischar(cellStr)
   cellStr = {cellStr};
elseif size(cellStr,1) > 1
   cellStr = reshape(cellStr, 1, []);
end
   
