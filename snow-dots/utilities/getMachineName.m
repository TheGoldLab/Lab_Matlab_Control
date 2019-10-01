function name = getMachineName()
%function name = getMachineName()
%
% Utility to ensure consistency
if isunix()
   [~,name] = system('scutil --get ComputerName');
   name = deblank(name);
else
   name = 'windows';
end
