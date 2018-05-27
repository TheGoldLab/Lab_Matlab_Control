function eventName = RTDgetAndSaveNextEvent(datatub, acceptedEvents, eventTag)
% function eventName = RTDgetAndSaveNextEvent(datatub, acceptedEvents, eventTag)
% 
% RTD = Response-Time Dots
%
% call dotsReadable.getNext event and save the data
%
% Arguments:
%  
%  datatub        ... tub o' data
%  acceptedEvents ... cell array of strings acceptedEvents to list names of
%                       events that can be used
%  eventTag       ... string used to store timing information in trial struct

% Created 5/11/18 by jig

%% ---- Call dotsReadable.getNext
%
% data has the form [ID, value, time]
[eventName, data] = getNextEvent(datatub{'Control'}{'userInputDevice'}, ...
   [], acceptedEvents);

if ~isempty(eventName)
   
   % Store the timing data
   task = datatub{'Control'}{'currentTask'};
   task.trialData(task.trialIndex).(sprintf('time_%s', eventTag)) = data(3);
end

