function [localTime, screenTime, screenRoundTripTime, uiTime] = ...
   syncTiming(screenEnsemble, ui)
% function [localTime, screenTime, screenRoundTripTime, uiTime] = ...
%    syncTiming(screenEnsemble, ui)
%
% RTD = Response-Time Dots
%
% Get local time, and use the screen ensemble to get the (possibly remote) 
%  screen time, and get the ui (e.g., eye-tracker) times
%
% Arguments:
%  screenEnsemble    ... holds the dotsTheScreen object, to get timing
%  ui                ... the current user-interface object
%
% 11/21/18 written by jig

% Ask for the time from the screen object, but only accept it if it comes
% quickly
roundTrip = inf;
start = mglGetSecs;
timeout = false;
while roundTrip > 0.01 && ~timeout;
   before = mglGetSecs;
   screenTime = screenEnsemble.callObjectMethod(@getCurrentTime);
   after = mglGetSecs;
   roundTrip = after - before;
   timeout = (after-start) > 0.5;
end
uiTime              = ui.getDeviceTime();
localTime           = mean([before after]);
screenRoundTripTime = roundTrip;

