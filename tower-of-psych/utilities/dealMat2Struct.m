function structArray = dealMat2Struct(structIn, varargin)
% function structArray = dealMat2Struct(structIn, varargin)
%
% Makes an array of the given structure, dealing values from the given
%  arrays into the specified fields
%
% Arguments:
%  structIn       ... a scalar structure
%
%  the remaining arguments are in pairs:
%     fieldname   ... string name of the structure field to fill
%     values      ... matrix of values to deal into the array. These all
%                          must be the same size
%
% Created 5/27/18 by jig

for ii = 1:2:nargin-1
   
   fieldname = varargin{ii};
   values    = varargin{ii+1};

   if ii == 1
      structArray = repmat(structIn, size(values));
   end
   
   % make a cell array to deal
   valuesCell = num2cell(values);
   
   % deal them into the struct array
   [structArray.(fieldname)] = deal(valuesCell{:});
end
