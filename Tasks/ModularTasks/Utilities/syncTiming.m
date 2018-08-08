function [localTime, screenTime, screenRoundTripTime, uiTimes, uiRoundTripTimes] = ...
   syncTiming(screenEnsemble, uis)
% function [localTime, screenTime, screenRoundTripTime, uiTime, uiRoundTripTime] = ...
%    syncTiming(screenEnsemble, uis)
%
% RTD = Response-Time Dots
%
% Get local time, and use the screen ensemble to get the (possibly remote) 
%  screen time, and get the ui (e.g., eye-tracker) times
%
% Arguments:
%  screenEnsemble    ... holds the dotsTheScreen object, to get timing
%  uis               ... the current user-interface object
%
% 11/21/18 written by jig

% Ask for the time from the screen object, but only accept it if it comes
% quickly

% parse args
if nargin < 1
   localTime           = mglGetSecs();
   screenTime          = nan;
   screenRoundTripTime = nan;
   uiTimes             = nan;
   uiRoundTripTimes    = nan;
   return
end

if nargin < 2
   uis = [];
end

% Get screen time
screenTime = nan;
if nargin >= 1 && ~isempty(screenEnsemble)
   screenRoundTripTime = inf;
   start               = mglGetSecs;
   after               = start;
   while (screenRoundTripTime > 0.01) && ((after-start) < 0.5);
      before              = mglGetSecs;
      screenTime          = screenEnsemble.callObjectMethod(@getCurrentTime);
      after               = mglGetSecs;
      screenRoundTripTime = after - before;
   end
   localTime = mean([before after]);
end

% Get ui times
if iscell(uis)
   uiTimes          = nans(length(uis),1);
   uiRoundTripTimes = nans(length(uis), 1);   
   for ii = 1:length(uis)
      uiTimes(ii)          = uis{ii}.getDeviceTime();
      uiRoundTripTimes(ii) = mglGetSecs - after;
   end
elseif ~isempty(uis)
      uiTimes          = uis.getDeviceTime();
      uiRoundTripTimes = mglGetSecs - after;
else
   uiTimes          = nan;
   uiRoundTripTimes = nan;
end