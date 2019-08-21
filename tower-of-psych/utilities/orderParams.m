function params_ = orderParams(disordered, template, makeStruct)
% function params_ = orderParams(disordered, template, makeStruct)
%
% Utility for re-ordering parameter/value pairs. Useful for dealing with
%  the unmatched parameters returned by parser.
%
% Arguments:
%  disordered: struct of param values in the wrong order
%  template: cell array of parameter/value pairs in the correct order
%  makeStruct: whether to return a cell array of parameter/value pairs
%                    or struct (default)

if nargin < 1 || isempty(disordered)

   % Return nothing
   params_ = [];
else
   
   % Reorder the fields
   names = template(cellfun(@(x) ischar(x), template));
   Lnames = ismember(names, fieldnames(disordered));
   params_ = orderfields(disordered, cell2struct(cell(sum(Lnames),1), names(Lnames)));
   
   % Convert to list
   if nargin < 3  || ~makeStruct
      
      % return a list
      cellA = cat(2, fieldnames(params_), struct2cell(params_));
      params_ = reshape(cellA', 1, []);
   end
end