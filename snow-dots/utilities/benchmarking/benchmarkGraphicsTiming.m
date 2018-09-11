% benchmarkGraphicsTiming
%
% Shows a bunch of targets (top) or RDK (bottom) of increasing complexity &
% tests for skipped frames

SCREEN_INDEX = 0;  % 0=small rectangle on main screen; 1=main screen; 2=secondary

try
    % open the screen
    dotsTheScreen.reset('displayIndex', SCREEN_INDEX);
    dotsTheScreen.openWindow();
    
    theScreen = dotsTheScreen.theObject();
    frameInt = 1./theScreen.windowFrameRate.*1000; % in ms
    
    %% TARGETS
    %
    % draw in screen rect
    screenHoriz = theScreen.displayPixels(3)./2./theScreen.pixelsPerDegree;
    screenVert  = theScreen.displayPixels(4)./2./theScreen.pixelsPerDegree;
    
    % make target(s) & store timing data
    NTS        = [50 500:500:5000];
    numTs      = length(NTS);
    NUM_FRAMES = 50;
    timeData   = nans(NUM_FRAMES, numTs);
    for nn = 1:numTs
        numTargets = NTS(nn);
        target = dotsDrawableTargets();
        target.xCenter = rand(numTargets, 1).*screenHoriz.*2-screenHoriz;
        target.yCenter = rand(numTargets, 1).*screenVert.*2-screenVert;
        target.width   = 0.7;
        target.height  = 0.7;
        target.colors  = rand(numTargets, 3);
        
        % draw 'em
        startTime = mglGetSecs();
        for ii = 1:NUM_FRAMES
            target.xCenter = target.xCenter + rand(numTargets,1)-0.5;
            target.yCenter = target.yCenter + rand(numTargets,1)-0.5;
            Lwrap     = abs(target.xCenter) > screenHoriz | abs(target.yCenter) > screenVert;
            target.xCenter(Lwrap) = rand(sum(Lwrap), 1).*screenHoriz.*2-screenHoriz;
            target.yCenter(Lwrap) = rand(sum(Lwrap), 1).*screenVert.*2-screenVert;
            dotsDrawable.drawFrame({target});
            timeData(ii,nn) = (mglGetSecs - startTime).*1000;
        end
        theScreen.blank();
    end
    
    %% RDK
    %
    % make dots & store timing data
    DDS        = 1000:2000:20000;
    numDDs     = length(DDS);
    NUM_FRAMES = 50;
    timeData2  = nans(NUM_FRAMES, numDDs);
    dots       = dotsDrawableDotKinetogram();
    dots.diameter  = 15;
    dots.pixelSize = 3;
    for nn = 1:numDDs
        % draw 'em
        dots.density   = DDS(nn);
        dots.isVisible = true;
        startTime = mglGetSecs();
        dots.prepareToDrawInWindow();
        for ii = 1:NUM_FRAMES
            dotsDrawable.drawFrame({dots}, true);
            timeData2(ii,nn) = (mglGetSecs - startTime).*1000;
        end
        theScreen.blank();
    end
    
    % close the drawing window
    dotsTheScreen.closeWindow();
    
catch
    % close the drawing window
    dotsTheScreen.closeWindow();
end

% plot some stats
figure
subplot(2,1,1); cla reset; hold on;
plot(NTS, sum(diff(timeData)>frameInt+2), 'ko', 'MarkerSize', 8)
axis([NTS(1) NTS(end) -1 NUM_FRAMES+1])
xlabel('Number of targets')
ylabel('Number of skipped frames');

subplot(2,1,2); cla reset; hold on;
plot(DDS([1 end]), [0 0], 'k:');
plot(DDS, sum(diff(timeData2)>frameInt+2), 'ko', 'MarkerSize', 8)
axis([DDS(1) DDS(end) -1 NUM_FRAMES+1])
xlabel('Number of dots')
ylabel('Number of skipped frames');


