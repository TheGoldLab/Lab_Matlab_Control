function ordered_ = orderParams(disordered, template, makeCellArray)
% function ordered_ = orderParams(disordered, template, makeCellArray)
%
% Utility for re-ordering parameter/value pairs. Useful for dealing with
%  the unmatched parameters returned by parser.
%
% Arguments:
%  disordered: struct of param values in the wrong order
%  template: cell array of parameter/value pairs in the correct order
%  makeCellArray: whether to return a cell array of parameter/value pairs
%                    or struct (default)

if nargin < 1 || isempty(disordered)
   ordered_ = [];
else
   names = template(cellfun(@(x) ischar(x), template));
   Lnames = ismember(names, fieldnames(disordered));
   ordered_ = orderfields(disordered, cell2struct(cell(sum(Lnames),1), names(Lnames)));
   
   if nargin >= 3 && makeCellArray
      cellA = cat(2, fieldnames(ordered_), struct2cell(ordered_));
      ordered_ = reshape(cellA', 1, []);
   end
end