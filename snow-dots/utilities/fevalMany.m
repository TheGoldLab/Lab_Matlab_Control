function fevalMany(fevalables)
%% function fevalMany(fevalables)
%
% Utility for calling "feval" on a bunch of fevalables, stored as cell
% arrays
%
% Created 5/16/19 by jig

% No args given
if nargin < 1 || isempty(fevalables)
   return
   
   % Arg is string or function handle
elseif ischar(fevalables)
   feval(fevalables);
   
   % Arg is cell array, check first arg
elseif iscell(fevalables{1})
   
   for ii = 1:length(fevalables)
      feval(fevalables{ii}{:});
   end
   
else
   feval(fevalables{:});
end