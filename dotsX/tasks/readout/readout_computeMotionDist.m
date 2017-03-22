function readout_computeMotionDist(inc)
% read a new mean dot direction and std, and compute a Gaussian
% distrubution over the interval 1:360
global ROOT_STRUCT

% always compute the dot direction from the local machine,
%   where the dXtc helpers are.
dirCondition = rGet('dXtc', 1, 'value');
plusMinus = rGet('dXtc', 2, 'value');
dir = dirCondition + inc*plusMinus;

% save the nominal, mean direction in the dXdots
%   this is useful for the dXlr
rSet('dXdots', 1, 'direction', dir);

% let dXlr know the stimulus condition,
%   it can compute "right" = more clockwise
rSet('dXlr', 1, 'intercept', (90-dirCondition)*pi/180);

% find the arrow postion around the dots circle
options = [dirCondition+inc, dirCondition-inc];
R = 7;
x = R*cosd(options);
y = R*sind(options);

% move the arrows and targets
%   target # 3 is "left" or "less clockwise" and Green
%   target # 4 is "right" or "more clockwise" and Red
for ii = 1:2
    rSet('dXimage', ii, 'x', x(ii), 'y', y(ii), 'rotationAngle', -options(ii));
    rSet('dXtarget', ii+2, 'x', x(ii), 'y', y(ii));
end

% save ecode for final dot direction
buildFIRA_addTrial('ecodes', {dir, {'real_dot_direction'}, {'value'}});

% get the dots Gaussian std
std = rGet('dXtc', 3, 'value');
buildFIRA_addTrial('ecodes', {std, {'dot_Gauss_std'}, {'value'}});

% set dot distribution locally, or generate a compact string for remote
if ROOT_STRUCT.screenMode == 2

    % special remote behavior:

    % set the mean and std to a new variables on the remote machine
    msg = sprintf('dir=%.5f;std=%.5f;', dir, std);
    sendMsgH(msg);

    % use the mean to compute the domain and CDF of directions
    msg = 'dirDomain = dir + (-180:180);';
    sendMsgH(msg);
    msg = 'dirCDF = normcdf(dirDomain, dir, std);';
    sendMsgH(msg);

    % set these new values to the dXdots on the remote machine
    msg = 'rSet(''dXdots'', 1, ''dirDomain'', dirDomain, ''dirCDF'', dirCDF);';
    sendMsgH(msg);
else

    % normal local behavior
    dirDomain = dir + (-180:180);
    dirCDF = normcdf(dirDomain, dir, std);
    rSet('dXdots', 1, 'dirDomain', dirDomain, 'dirCDF', dirCDF);
end