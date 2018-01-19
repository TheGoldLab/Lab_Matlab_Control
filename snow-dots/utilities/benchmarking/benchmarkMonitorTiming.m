% benchmarkMonitorTiming
%
%  Estimate luminance transition times for a monitor.
%
%  Software requirements:
%     1. https://github.com/TheGoldLab/Lab-Matlab-Utilities
%           (where this directory resides)
%     2. https://github.com/TheGoldLab/Lab-Matlab-Control
%           (for control of the PMD1208fs device)
%
%  Hardware requirements:
%     1. PMD1208fs
%        https://www.mccdaq.com/usb-data-acquisition/USB-1208FS.aspx
%        see file "pmd1208fs_specs.pdf" for technical specs
%     2. OSI Optoelectronics PIN-10D photodiode.
%        see file "Photoconductive-Photodiodes.pdf" for technical specs
%     3. Cable for connecting photodiode (BNC connector) to PMD device
%        (screw terminals)
%
%  Hardware setup:
%     1. Attach the photodiode to the PMD device. We are using the device
%        in DIFFERENTIAL MODE, with default channel 0. So you should plug
%        the leads into terminals 1 and 2
%     2. Tape or hold the photodiode to the part of the screen where the
%        target will show
%     3. Run the script


%% DEFINE TEST PARAMETERS
SCREEN_INDEX            = 0;  % 0=small rectangle on main screen; 1=main screen; 2=secondary
NUM_LUMINANCE_STEPS     = 5;
NUM_REPS_PER_LUMINANCE  = 10;
FLASH_DURATION          = 0.2;   % in ms
TARGET_CENTER           = [0 0]; % x, y
TARGET_DIAMETER         = 10;
PMD_CHANNEL             = 0; % differential channel 0 is terminals 1 & 2
PMD_GAIN                = 7; % 20x = +/-1V; see MCCFormatReport
PMD_SAMPLE_FREQUENCY    = 2000;

%% Setup screen
dotsTheScreen.reset('displayIndex', SCREEN_INDEX);
dotsTheScreen.openWindow();
theScreen = dotsTheScreen.theObject();

%% Make target object
target = dotsDrawableTargets();
target.xCenter = TARGET_CENTER(1);
target.yCenter = TARGET_CENTER(2);
target.width   = TARGET_DIAMETER;
target.height  = TARGET_DIAMETER;

%% Set up array of luminance values
%  here are just the bright values ... later we'll
%  add the complementary dim values, then an extra
%  so we have an equal number of bright->dim and
%  dim->bright transitions
if NUM_LUMINANCE_STEPS == 0
   bright_luminances = 0;
else
   bright_luminances = linspace(0,0.4,NUM_LUMINANCE_STEPS);
end
num_frames = NUM_REPS_PER_LUMINANCE*2+1;

%% Configure device for input
aIn = AInScan1208FS();
aIn.channels  = PMD_CHANNEL;
aIn.gains     = PMD_GAIN; % 20x = +/-1V; see MCCFormatReport
aIn.frequency = PMD_SAMPLE_FREQUENCY;
aIn.nSamples  = ceil((FLASH_DURATION+0.1)*aIn.frequency);

%% Setup data matrices
frameTimingData = nans(4, num_frames, NUM_LUMINANCE_STEPS);
analogData      = nans(aIn.nSamples, 2, num_frames, NUM_LUMINANCE_STEPS);

%% Loop through each luminance step
for ll = 1:NUM_LUMINANCE_STEPS
   
   % make matrix of [bright dark; dark bright] luminances to show
   %  add one at the end for equal number of bright->dark and
   %  dark->bright transitions
   luminances = cat(1, ...
      repmat([bright_luminances(ll); 1-bright_luminances(ll)], ...
      NUM_REPS_PER_LUMINANCE, 1), bright_luminances(ll));
   
   % loop through the luminances
   for ff = 1:num_frames
      
      % set the luminance
      target.colors = ones(1,3).*luminances(ff);
      
      % Set up scanning
      frameTimingData(1,ff,ll) = aIn.prepareToScan();
      frameTimingData(2,ff,ll) = aIn.startScan(); % host CPU time, when start ack'd by USB device
            
      % draw it, save the time
      timing = dotsDrawable.drawFrame({target});
      frameTimingData(3,ff,ll) = timing.onsetTime;
      
      % wait
      pause(FLASH_DURATION);
      
      % stop scanning
      frameTimingData(4,ff,ll) = aIn.stopScan();
   
      % get the data
      [chans, volts, times, uints] = aIn.getScanWaveform();

      % save with zero'ed timebase
      analogData(1:length(chans),:,ff,ll) = [ ...
         times'-times(1), ...
         volts'];      
   end
end

% close drawing window
dotsTheScreen.closeWindow();

% close the device
aIn.close();

%% Plot raw data

% to scale the data
mindat = nanmin(reshape(analogData(:,2,:,:),[],1));
maxdat = nanmax(reshape(analogData(:,2,:,:),[],1));

% for the exponential fits
inits = [40 0.3 10 0.35; 0 0 0.1 0; 100 1 20 1];
fits  = nans(NUM_REPS_PER_LUMINANCE, size(inits,2), 2, NUM_LUMINANCE_STEPS);

for ll = 1:NUM_LUMINANCE_STEPS
   for dd = 1:2
      subplot(NUM_LUMINANCE_STEPS,2,(ll-1)*2+dd); cla reset; hold on;
      if dd == 1
         lums = [1-bright_luminances(ll) bright_luminances(ll)];
      else
         lums = [bright_luminances(ll) 1-bright_luminances(ll)];
      end
      
      for rr = 2:NUM_REPS_PER_LUMINANCE
         
         % get this frame
         frame = dd+(rr-1)*2;
         
         % start time is reported onset time of luminance change
         t0    = frameTimingData(3,frame,ll)-frameTimingData(2,frame,ll);
         
         % get the data
         Lgood = analogData(:,1,frame,ll)>=t0;
         times = (analogData(Lgood,1,frame,ll)-t0).*1000;
         volts = analogData(Lgood,2,frame,ll);
         
         % plot the raw data
         plot(times, volts, 'k.');
         
         % fit to exponential
         yStartg = volts(1);
         yEndg   = volts(end);
         [Y,I]   = max(abs(diff(nanrunmean(volts,5))));
         tStartg = min(times(I));
         
         % to pass data
         myFun = @(x)expFitErr(x, [times volts]);
         
         % do the fit with patternsearch
         ff = patternsearch(myFun,...
            [tStartg yStartg 3 yEndg],[],[],[],[],inits(2,:),inits(3,:),[], ...
            psoptimset('Display', 'off'));
         fits(rr,:,dd,ll) = ff;
         
         % plot the fit
         plot(times, expFitVal(ff(1), ff(2), ff(3), ff(4), times), 'r-');
         axis([0 120 mindat*.98 maxdat*1.02]);
      end
      
      % Report fits in the title
      title(sprintf('Lum = %.2f->%.2f, delay=%.2f [%.2f %.2f], tau=%.2f [%.2f %.2f]', ...
         lums(1), lums(2), ...
         nanmedian(fits(:,1,dd,ll)), nanmin(fits(:,1,dd,ll)), nanmax(fits(:,1,dd,ll)), ...
         nanmedian(fits(:,3,dd,ll)), nanmin(fits(:,3,dd,ll)), nanmax(fits(:,3,dd,ll))));
      
      % label axes for the bottom plots
      if ll == NUM_LUMINANCE_STEPS
         xlabel('Time since reported stimulus onset (msec)');
         ylabel('Voltage');
      end      
   end
end




