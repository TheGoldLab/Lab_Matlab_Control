% analysis script
%
% Created 6/18/2018 by jig

testFilename = 'data_2018_08_08_08_55';

FIRA = makeFIRAfromModularTasks(testFilename, 'DBSStudy');

figure

% timing indices
sgis = cat(2, ...
   find(strcmp(FIRA.ecodes.name, 'time_targsOn'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_dotsOn'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_targsOff'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_fixOff'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_dotsOff'), 1), ...
   find(strcmp(FIRA.ecodes.name, 'time_fdbkOn'), 1));
rti = find(strcmp(FIRA.ecodes.name, 'RT'), 1);

% task indices
%  1  = VGS
%  2  = MGS
%  3  = Quest dots
%  7  = Speed, no bias
%  10 = Accuracy, no bias
tis = [1 2 3 7 10];
nts = length(tis);
lm  = 15;
clf
for tt = 1:nts
   
   for ii = find(FIRA.ecodes.data(:,1)==tis(tt))'
      
      xax   = FIRA.analog.data{ii}(:,1);
      xs    = FIRA.analog.data{ii}(:,2);
      ys    = FIRA.analog.data{ii}(:,3);
      Lgood = xax>=(FIRA.ecodes.data(ii,sgis(1))-200) & xax<=FIRA.ecodes.data(ii,sgis(6));
            
      % get index of saccade soon after RT
      if ecodes.data(tt,1) <= 2
         refTime = FIRA.ecodes.data(ii,sgis(4)); % Fix off for VGS/MGS
      else
         refTime = FIRA.ecodes.data(ii,sgis(2)); % Dots on
      end
      fixIndex    = find(xax<=FIRA.ecodes.data(ii,sgis(4)),1);
      sacEndIndex = find(xax<=(refTime+FIRA.ecodes.data(tt,rti)+50),1);

      % x vs y
      subplot(nts, 2, (tt-1)*2+1); hold on;
      plot([-lm lm], [0 0], 'k:');
      plot([0 0], [-lm lm], 'k:');
      plot(xs(Lgood), ys(Lgood), 'k-');
      plot(xs(fixIndex), ys(fixIndex), 'go');
      plot(xs(sacEndIndex), ys(sacEndIndex), 'go', 'MarkerFaceColor', 'g');
      axis([-lm lm -lm lm]);
      
      % x,y vs t
      subplot(nts, 2, (tt-1)*2+2); hold on;
      plot([-1 6], [0 0], 'k:');
      plot(xax(Lgood), xs(Lgood), 'r-');
      plot(xax(Lgood), ys(Lgood), 'b-');
   end
end
