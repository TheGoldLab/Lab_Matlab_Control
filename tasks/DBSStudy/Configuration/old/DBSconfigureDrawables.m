function DBSconfigureDrawables(topNode)
% function DBSconfigureDrawables(topNode)
%
% configuration routine for dotsDrawable classes
%  plus the screen
%
% Separated from DBSconfigure for readability
%
% Arguments:
%  topNode ... the topsTreeNode at the top of the hierarchy
%
% 5/28/18 created by jig

%% ---- Make the screen ensemble
%
screenEnsemble = makeScreenEnsemble( ...
   topNode.nodeData{'Settings'}{'useRemoteDrawing'}, topNode.nodeData{'Settings'}{'displayIndex'});
topNode.nodeData{'Graphics'}{'screenEnsemble'} = screenEnsemble;

% Make a text ensemble for showing messages.
textEnsemble = makeTextEnsemble('text', 2, [], screenEnsemble);
topNode.nodeData{'Graphics'}{'textEnsemble'} = textEnsemble;

%% ---- Add screen start/finish fevalables to the main topsTreeNode
%
% Start: open the screen
topNode.addCall('start', {@callObjectMethod, screenEnsemble, @open}, 'openScreen');

% Finish: close the screen and show a nice message (done in reverse order)
topNode.addCall('finish', {@callObjectMethod, screenEnsemble, @close}, 'closeScreen');
topNode.addCall('finish', {@drawTextEnsemble, textEnsemble, {'All done.', 'Thank you!'}, 2, 0}, 'finalMessage');
