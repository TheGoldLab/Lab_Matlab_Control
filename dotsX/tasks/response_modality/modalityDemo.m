rInit('remote')

% % -45
% right = -45;
% l = 'up / left';
% r = 'down / right';

% +45
right = 45;
l = 'down / left';
r = 'up / right';

y = -7;

left = 180+right;
rGroup('gXmodality_graphics')
rAdd('dXtext', 1, 'visible', true, 'string', l, 'x', -2);
rSet('dXdots', 1, 'visible', true, 'y', y, ...
    'coherence', 90, 'direction', left);

WaitSecs(.2);
rGraphicsDraw(inf);

rSet('dXtext', 1, 'string', r);
rSet('dXdots', 1, 'direction', right);

WaitSecs(.2);
rGraphicsDraw(inf);

rDone