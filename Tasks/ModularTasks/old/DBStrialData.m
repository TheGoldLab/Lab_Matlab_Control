function trialData = DBStrialData()
% function trialData = DBStrialData()
%
% Utility function for defining a standard trialData structure for dots and
% other tasks
%
% Createdy 5/28/18 by jig

trialData = struct( ...
   'taskIndex', nan, ...
   'trialIndex', nan, ...
   'direction', nan, ...
   'coherence', nan, ...
   'choice', nan, ...
   'RT', nan, ...
   'correct', nan, ...
   'time_screen_roundTrip', 0, ...
   'time_local_trialStart', nan, ...
   'time_ui_trialStart', nan, ...
   'time_screen_trialStart', nan, ...
   'time_TTLFinish', nan, ...
   'time_fixOn', nan, ...
   'time_targsOn', nan, ...
   'time_dotsOn', nan, ...
   'time_targsOff', nan, ...
   'time_fixOff', nan, ...
   'time_choice', nan, ...
   'time_dotsOff', nan, ...
   'time_fdbkOn', nan, ...
   'time_local_trialFinish', nan, ...
   'time_ui_trialFinish', nan, ...
   'time_screen_trialFinish', nan);
