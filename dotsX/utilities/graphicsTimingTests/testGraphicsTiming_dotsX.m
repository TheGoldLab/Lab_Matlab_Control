% testGraphicsTiming_dotsX
%
% Shows a bunch of targets (top) or RDK (bottom) of increasing complexity &
% tests for skipped frames

% open the screen
rInit('local');
frameInt = 1./rGet('dXscreen','frameRate').*1000; % in ms

%% TARGETS
%

% draw in screen rect
sr  = rGet('dXscreen', 'screenRect');
ppd = rGet('dXscreen', 'pixelsPerDegree');
screenHoriz = sr(3)./2.1./ppd;
screenVert  = sr(4)./2.1./ppd;

% make target(s) & store timing data
NTS        = [50 500:500:5000];
numTs      = length(NTS);
NUM_FRAMES = 50;
timeData   = nans(NUM_FRAMES, numTs);
for nn = 1:numTs;
   numTargets = NTS(nn);
   rAdd('dXtargets', 1, 'visible', true, 'diameter', 1, 'cmd', 1, ...
      'penWidth', 2, ...
      'x', rand(numTargets, 1).*screenHoriz.*2-screenHoriz, ...
      'y', rand(numTargets, 1).*screenVert.*2-screenVert, ...
      'color', round(rand(numTargets, 3).*255));
   
   startTime = GetSecs();
   for ii = 1:NUM_FRAMES
      xs = rGet('dXtargets', 'x') + rand(numTargets,1)-0.5;
      ys = rGet('dXtargets', 'y') + rand(numTargets,1)-0.5;
      Lwrap   = abs(xs) > screenHoriz | abs(ys) > screenVert;
      xs(Lwrap) = rand(sum(Lwrap), 1).*screenHoriz.*2-screenHoriz;
      ys(Lwrap) = rand(sum(Lwrap), 1).*screenVert.*2-screenVert;
      rGraphicsSetDraw('dXtargets', 1, 'x', xs, 'y', ys);
      timeData(ii,nn) = (GetSecs - startTime).*1000;
   end
   rRemove('dXtargets', 1);
end
rGraphicsBlank;

%% RDK
%

% make dots & store timing data
DDS        = 500:500:4000;
numDDs     = length(DDS);
NUM_FRAMES = 50;
timeData2  = nans(NUM_FRAMES, numDDs);
rAdd('dXdots', 1, 'visible', true, 'direction', 0.00, ...
   'speed', 3, 'diameter', 15, 'coherence', 50);
for nn = 1:numDDs;
   rSet('dXdots', 1, 'density', DDS(nn));
   startTime = GetSecs();
   for ii = 1:NUM_FRAMES
      rGraphicsDraw();
      timeData2(ii,nn) = (GetSecs - startTime).*1000;
   end
end

% close the screen
rGraphicsBlank;
rDone;

% plot number of bad frames
figure

% Targets
subplot(2,1,1); cla reset; hold on;
plot(NTS, sum(diff(timeData)>frameInt+2), 'k.', 'MarkerSize', 8)
axis([NTS(1) NTS(end) -1 NUM_FRAMES+1])
xlabel('Number of targets')
ylabel('Number of skipped frames');

% Dots
subplot(2,1,2); cla reset; hold on;
plot(DDS([1 end]), [0 0], 'k:');
plot(DDS, sum(diff(timeData2)>frameInt+2), 'k.', 'MarkerSize', 8)
axis([DDS(1) DDS(end) -1 NUM_FRAMES+1])
xlabel('Number of dots')
ylabel('Number of skipped frames');

% plot average time/frame
% subplot(2,1,2); cla reset; hold on;
% plot(DDS([1 end]), frameInt.*[1 1], 'k:');
% plot(repmat(DDS,4,1), prctile(diff(timeData2),[0 25 75 100]), 'r.', 'MarkerSize', 8);
% plot(DDS, median(diff(timeData2)), 'k.', 'MarkerSize', 8);
% plot(DDS, mean(diff(timeData2)), 'k.', 'MarkerSize', 8);
% axis([DDS(1) DDS(end) 0 40])

%% Long RDK

rInit('local');
frameInt = 1./rGet('dXscreen','frameRate').*1000; % in ms

% make dots & store timing data
NUM_FRAMES = round(rGet('dXscreen','frameRate').*100);
timeData3  = nans(NUM_FRAMES, 1);
rAdd('dXdots', 1, 'visible', true, 'direction', 0.00, ...
   'speed', 3, 'diameter', 15, 'coherence', 50, 'density', 100);
startTime = GetSecs();
for ii = 1:NUM_FRAMES
   rGraphicsDraw();
   timeData3(ii) = (GetSecs - startTime).*1000;
end
rGraphicsBlank;
rDone;

% histogram of frame times
figure
hist(diff(timeData3))
