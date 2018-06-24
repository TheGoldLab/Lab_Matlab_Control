function DBSconfigureDrawables(datatub)
% function DBSconfigureDrawables(datatub)
%
% configuration routine for dotsDrawable classes
%  plus the screen
%
% Separated from DBSconfigure for readability
%
% 5/28/18 created by jig

%% ---- Make the screen ensemble
%
screenEnsemble = makeScreenEnsemble( ...
   datatub{'Settings'}{'useRemoteDrawing'}, datatub{'Settings'}{'displayIndex'});
datatub{'Graphics'}{'screenEnsemble'} = screenEnsemble;

% Make a text ensemble for showing messages.
textEnsemble = makeTextEnsemble('text', 2, [], screenEnsemble);
datatub{'Graphics'}{'textEnsemble'} = textEnsemble;

%% ---- Add screen start/finish fevalables to the main topsTreeNode
%
% Start: open the screen
addCall(datatub{'Control'}{'startCallList'}, ...
   {@callObjectMethod, screenEnsemble, @open}, 'openScreen');

% Finish: close the screen and show a nice message (done in reverse order)
addCall(datatub{'Control'}{'finishCallList'}, ...
   {@callObjectMethod, screenEnsemble, @close}, 'closeScreen');
addCall(datatub{'Control'}{'finishCallList'}, ...
   {@drawTextEnsemble, textEnsemble, {'All done.', 'Thank you!'}, 2, 0}, 'finalMessage');
