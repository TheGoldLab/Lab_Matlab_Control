function samples_ = benchmarkMonitorLuminance(optiCAL, color, numSamples)
% function samples_ = benchmarkMonitorLuminance(optiCAL, color, numSamples)
%
% Shows a target at the given color and measures and records the luminance
%  using the optiCAL device
%
% This function assumes that:
%   1. the optiCAL device is connected to the host computer using
%        the USB-to-serial device
%   2. If you are connecting using the Keyspan USA-19HS USB-to-serial
%        connector, make sure you have the appropriate driver
%        installed for your operating system:
%        https://www.tripplite.com/support/USA19HS
%   3. Find the location of the device:
%        --> In a terminal window, type 'ls /dev/tty.*'
%        --> It should be something like '/dev/tty.USA19H1461P1.1'
%        --> Use this as the first argument
%       --> Use "instrfind" to find open serial objects
%   4. The sensor is suctioned onto the middle of the screen
%
% Arguments:
%   1 ... location of optiCAL device (see above)
%   2 ... [r g b] color or keyword 'gamma'
%   3 ... number of samples to read
% 
% Returns:
%    Samples in units of cd/m^2

% check arguments
if nargin < 1 || isempty(optiCAL)
   optiCAL = '/dev/tty.USA19H1461P1.1';
end

% set to the given [r g b]
if nargin < 2 || isempty(color)
   color = 'gamma';
end

% get samples
if nargin < 3 || isempty(numSamples)
   numSamples = 50;
end

% set up the optiCAL device to start taking measurements
OP = opticalSerial(optiCAL);

if isempty(OP)
   disp('benchmarkMonitorLuminance: Cannot make opticalSerial object')
   return
end

%% Setup screen
SCREEN_INDEX  = 0;  % 0=small rectangle on main screen; 1=main screen; 2=secondary
dotsTheScreen.reset('displayIndex', SCREEN_INDEX);
dotsTheScreen.openWindow();

% make and draw the target
% create a targets object
target = dotsDrawableTargets();
target.xCenter = 0;
target.yCenter = 0;
target.width   = 20;
target.height  = 20;

if strcmp(color, 'gamma')
   
   % show a gamma plot
   NUM_LUMINANCES = 256;
   samples_ = nans(NUM_LUMINANCES, 2);
   
   for ii = 1:NUM_LUMINANCES
      
      % increment luminance
      target.colors = ii./NUM_LUMINANCES.*ones(1,3);
   
      % draw it
      dotsDrawable.drawFrame({target});
      
      % get luminance reading
      OP.getLuminance(1);
      
      % save the values
      samples_(ii,:) = [target.colors(1) OP.values(end)];      
   end
   
   % plot it
   cla reset; hold on;
   plot(samples_(:,1), samples_(:,2), 'ko');
   set(gca, 'FontSize', 12);
   xlabel('Nominal value');
   ylabel('Measured value (cd/m^2)');
   
elseif numel(color)==3
   
   % just test given color
   target.colors  = color;

   % draw it
   dotsDrawable.drawFrame({target});
   
   % get luminance readings
   OP.getLuminance(numSamples, 0.1);

   % save the values
   samples_ = OP.values;
end
         
% close the optiCAL device
OP.close();

% close the OpenGL drawing window
dotsTheScreen.closeWindow();

