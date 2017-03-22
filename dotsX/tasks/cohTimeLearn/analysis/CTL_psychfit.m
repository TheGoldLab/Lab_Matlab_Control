%Summarize a session from the cohTimeLearn interleaved set of tasks
%This is written by KCL specifically for CTInterleavedsessions where the
%timing is 100, 200, 400 and 800 ms.  The code will have to be changed if
%the times are

clear all
global FIRA ROOT_STRUCT

% get a data file (or even files)
concatenateFIRAs(false);
if isempty(FIRA)
    return
end

% get ROOT_STRUCT so tasks are accessible
ROOT_STRUCT = FIRA.allHeaders(1).session;

[tasks, taskID, allNames] = unifyFIRATaskNames;
[sessionID, blockNum, days, subjects] = findFIRASessionsAndBlocks(2,2);
blocks = unique(blockNum(~isnan(blockNum)))';
numBlocks = length(blocks);

trialnum = strcmp(FIRA.ecodes.name, 'trial_num');
dotcoherence = strcmp(FIRA.ecodes.name, 'dotCoherence');
dotdir = strcmp(FIRA.ecodes.name, 'dot_dir');
viewingtime = strcmp(FIRA.ecodes.name, 'viewing_time');
task = strcmp(FIRA.ecodes.name, 'task_index');

eGood = strcmp(FIRA.ecodes.name, 'good_trial');
good = FIRA.ecodes.data (FIRA.ecodes.data(:,eGood)==1, :);

eCorrect = strcmp(FIRA.ecodes.name, 'correct');
correct = ~isnan(good(:,eCorrect));

practicedata = good(good(:, task)==1, :);
coherencequestdata = good(good (:, task)==2, :);
timequestdata = good(good(:,task)==3, :);

practice100 = practicedata (practicedata (:, viewingtime)==100,:);
practice200 = practicedata (practicedata (:, viewingtime)==200,:);
practice400 = practicedata (practicedata (:, viewingtime)==400,:);
practice800 = practicedata (practicedata (:, viewingtime)==800,:);

cohat100 = coherencequestdata (coherencequestdata (:, viewingtime)==100,:);
cohat200 = coherencequestdata (coherencequestdata (:, viewingtime)==200,:);
cohat400 = coherencequestdata (coherencequestdata (:, viewingtime)==400,:);
cohat800 = coherencequestdata (coherencequestdata (:, viewingtime)==800,:);


[min_difference, array_position_of100] = min(abs(timequestdata(:, viewingtime) - 100));
[min_difference, array_position_of200] = min(abs(timequestdata(:, viewingtime) - 200));
[min_difference, array_position_of400] = min(abs(timequestdata(:, viewingtime) - 400));
[min_difference, array_position_of800] = min(abs(timequestdata(:, viewingtime) - 800));

cohfortime100=timequestdata (array_position_of100, dotcoherence);
cohfortime200=timequestdata (array_position_of200, dotcoherence);
cohfortime400=timequestdata (array_position_of400, dotcoherence);
cohfortime800=timequestdata (array_position_of800, dotcoherence);

timeatcoh100ms=timequestdata(timequestdata(:, dotcoherence)==cohfortime100, :);
timeatcoh200ms=timequestdata(timequestdata(:, dotcoherence)==cohfortime200, :);
timeatcoh400ms=timequestdata(timequestdata(:, dotcoherence)==cohfortime400, :);
timeatcoh800ms=timequestdata(timequestdata(:, dotcoherence)==cohfortime800, :);

%correctincorrectpractice =...
%   (practice100(find(practice100(:, eCorrect))), ~isnan(practice100(:, eCorrect)),...
%     practice200(find(practice200(:, eCorrect))), ~isnan(practice200(:, eCorrect)),...
%     practice400(find(practice400(:, eCorrect))), ~isnan(practice400(:, eCorrect)),...
%     practice800(find(practice800(:, eCorrect))), ~isnan(practice800(:, eCorrect)));

% percentcorrectpractice=...
%    (100, mean(~isnan(practice100(:, eCorrect)))*100,...
%    200, mean(~isnan(practice200(:, eCorrect)))*100,...
%    400, mean(~isnan(practice400(:, eCorrect)))*100,...
%    800, mean(~isnan(practice800(:, eCorrect)))*100)

numberoftrials = length(cohat100);

dataforquickfit100=[cohat100(:, dotcoherence)/100, ~isnan(cohat100(:, eCorrect))];
dataforquickfit200=[cohat200(:, dotcoherence)/100, ~isnan(cohat200(:, eCorrect))];
dataforquickfit400=[cohat400(:, dotcoherence)/100, ~isnan(cohat400(:, eCorrect))];
dataforquickfit800=[cohat800(:, dotcoherence)/100, ~isnan(cohat800(:, eCorrect))];


f100=ctPsych_fit(@quick3, dataforquickfit100(:,1), dataforquickfit100(:,2))
f200=ctPsych_fit(@quick3, dataforquickfit200(:,1), dataforquickfit200(:,2))
f400=ctPsych_fit(@quick3, dataforquickfit400(:,1), dataforquickfit400(:,2))
f800=ctPsych_fit(@quick3, dataforquickfit800(:,1), dataforquickfit800(:,2))

cohs100 = dataforquickfit100(:,1);
pcor100 = dataforquickfit100(:,2);
cohs200 = dataforquickfit200(:,1);
pcor200 = dataforquickfit200(:,2);
cohs400 = dataforquickfit400(:,1);
pcor400 = dataforquickfit400(:,2);
cohs800 = dataforquickfit800(:,1);
pcor800 = dataforquickfit800(:,2);

subplot(2,2,1); plot_fit(cohs100, pcor100, f100)
xlabel ('% coherence')
ylabel ('% accuracy')
title ('100 msec Quick Fit')
axis([0 1 0 1])
set(gca,'XTick',0:.1:1)
subplot(2,2,2); plot_fit(cohs200, pcor200, f200)
xlabel ('% coherence')
ylabel ('% accuracy')
title ('200 msec Quick Fit')
axis([0 1 0 1])
set(gca,'XTick',0:.1:1)
subplot(2,2,3); plot_fit(cohs400, pcor400, f400)
xlabel ('% coherence')
ylabel ('% accuracy')
title ('400 msec Quick Fit')
axis([0 1 0 1])
set(gca,'XTick',0:.1:1)
subplot(2,2,4); plot_fit(cohs800, pcor800, f800)
xlabel ('% coherence')
ylabel ('% accuracy')
title ('800 msec Quick Fit')
axis([0 1 0 1])
set(gca,'XTick',0:.1:1)


