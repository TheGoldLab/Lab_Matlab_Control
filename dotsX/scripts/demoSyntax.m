% demoSyntax.m
%
% script for testing and demo'ing dotsX r* syntax

% always call rInit first
% see rInit.m for arguments

rInit('debug');

% add graphics objects
rAdd('dXtarget', 3);
rAdd('dXtarget', 1, 'diameter', 10);
rAdd('dXdots', 1, 'coherence', 999);

% get/set properties
rGet('dXtarget');
rGet('dXdots', 1, 'coherence');
rSet('dXtarget', [1 3], 'x', {-10 10});
rGet('dXtarget', 3, 'x')

% remove objects
rRemove('dXtarget', 3);

% done
rDone