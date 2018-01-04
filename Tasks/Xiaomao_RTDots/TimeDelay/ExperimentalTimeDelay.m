% %% Find timing error in real trials
% startTimes = state{'Stimulus'}{'trialStartTime'};
% endTimes = state{'Stimulus'}{'trialEndTime'};
% timePerTrial = endTimes - startTimes;
% timePerTrial(:,1) = timePerTrial(:,1) * 1000; % Eyelink is in ms
% 
% timeDiff = abs(timePerTrial(:,1) - timePerTrial(:,2));
% figure;
% histogram(timeDiff,10);
% 
% axis square;
% box off
% set(gca,'FontSize',16,'LineWidth',2);
% xlabel('Timing Difference (ms)','FontSize',18);
% ylabel('Trial Count','FontSize',18);
% set(gcf, 'PaperPositionMode', 'auto');
% 
% mean((timeDiff ./ ((timePerTrial(:,1) + timePerTrial(:,1))/2) ))