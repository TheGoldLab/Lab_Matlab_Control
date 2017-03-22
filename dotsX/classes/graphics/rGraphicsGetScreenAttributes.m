function [wn_, sr_, ppd_, fr_] = rGraphicsGetScreenAttributes
% function [wn_, sr_, ppd_, fr_] = rGraphicsGetScreenAttributes
%

% Copyright 2004 by Joshua I. Gold
% University of Pennsylvania

global ROOT_STRUCT

if ~isfield(ROOT_STRUCT, 'dXscreen')
    
    % no dXscreen object -- give warning and
    %   return dummy values
    disp('WARNING: rGraphicsGetScreenAttributes called with no initialized dXscreen object')    
    wn_  = 0;
    sr_  = [0 0 100 100];
    ppd_ = 10;
    fr_  = 60;
    
else
    
    dxs  = struct(ROOT_STRUCT.dXscreen);
    wn_  = dxs.windowNumber;
    sr_  = dxs.screenRect;
    ppd_ = dxs.pixelsPerDegree;
    fr_  = dxs.frameRate;
end
