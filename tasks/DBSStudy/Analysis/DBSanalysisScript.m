% analysis script
%
% Created 6/18/2018 by jig

% Get the data

studyTag = 'DBSStudy';

% spike2
filebase = '2019_02_14_11_10';
% pupil labs
% filebase = '2019_01_13_10_03';
[topNode, FIRA] = topsTreeNodeTopNode.loadRawData(studyTag, filebase);

% task indices
%  1  = VGS
%  2  = MGS
%  3  = Quest dots
%  7  = Speed, no bias
%  10 = Accuracy, no bias
%figure
tis = [1 2 3 7 10];
nts = length(tis);
lm  = 15;
td  = topNode.nodeData{'Settings'}{'targetDistance'}; 
clf

durs = FIRA.ecodes.data(:,strcmp(FIRA.ecodes.name, 'trialEnd')) - ...
   FIRA.ecodes.data(:,strcmp(FIRA.ecodes.name, 'trialStart'));

% For each task
for tt = 1:nts
   
   % For each trial
   for ii = find(FIRA.ecodes.data(:,1)==tis(tt))'
      
      tax   = FIRA.analog.data{ii}(:,1);
      xs    = nanrunmean(FIRA.analog.data{ii}(:,2),50);
      ys    = nanrunmean(FIRA.analog.data{ii}(:,3),50);
            
      % get index of saccade soon after RT
      if FIRA.ecodes.data(ii,1) <= 2
         refTime = FIRA.ecodes.data(ii,strcmp(FIRA.ecodes.name, 'fixationOff')); % Fix off for VGS/MGS
      else
         refTime = FIRA.ecodes.data(ii,strcmp(FIRA.ecodes.name, 'dotsOn')); % Dots on
      end
      
      % Event times
      fixIndex    = find(tax>=refTime,1);
      sacEndTime  = refTime+FIRA.ecodes.data(ii,strcmp(FIRA.ecodes.name, 'RT'))+0.1;
      sacEndIndex = find(tax>=(sacEndTime),1);
      Lgood       = tax>=(refTime-0.4) & tax<=min(sacEndTime+0.5, durs(ii));
      
      % rezero just before fpoff
      %xs = xs - nanmean(xs(fixIndex-10:fixIndex));
      %ys = ys - nanmean(ys(fixIndex-10:fixIndex));
      
      % x vs y
     %  subplot(nts, 2, (tt-1)*2+1); hold on;
     subplot(2,1,1); cla reset; hold on;
      plot([-lm lm], [0 0], 'k:');
      plot([0 0], [-lm lm], 'k:');
      if FIRA.ecodes.data(ii,1) <= 2
         plot([-td td 0 0], [0 0 -td td], 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 12);
      else
         plot([-td td], [0 0], 'ro', 'MarkerFaceColor', 'r', 'MarkerSize', 12);
      end
      plot(xs(Lgood), ys(Lgood), 'k-');
      plot(xs(fixIndex), ys(fixIndex), 'go', 'MarkerSize', 12);
      plot(xs(sacEndIndex), ys(sacEndIndex), 'go', 'MarkerFaceColor', 'g', 'MarkerSize', 12);
      axis([-lm lm -lm lm]);
      
      % x,y vs t
      %subplot(nts, 2, (tt-1)*2+2); hold on;
      subplot(2,1,2); cla reset; hold on;
      plot([-1 2], [0 0], 'k:');
      plot([0 0], [-lm lm], 'k:');
      plot([-1 2],  [td td], 'r:');
      plot([-1 2], -[td td], 'r:');
      plot(tax(Lgood)-refTime, xs(Lgood), 'c-');
      plot(tax(Lgood)-refTime, ys(Lgood), 'm-');
      
      r = input('next')
   end
end
