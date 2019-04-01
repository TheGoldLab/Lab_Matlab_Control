function args = struct2args(inputStruct)
% function args = struct2args(inputStruct)
%
% Utility to convert a struct into a cell array of name/property
%  pairs

vals = struct2cell(inputStruct);
args = cell(1, length(vals)*2);
args(1:2:end) = fieldnames(inputStruct);
args(2:2:end) = vals;
