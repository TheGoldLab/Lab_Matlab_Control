classdef dotsReadableSpike2 < dotsReadableEye
   % dotsReadableSpike2
   %
   % Convenience readable class for spike2 data that exists only to have a
   % standard calling convention for loading raw data
   %

   methods (Static)
   
      % Load raw data from file
      %
      % filename is string pathname where the pupil-labs folder is located
      % ecodes is optional ecodes struct
      %
      % Returns eye data struct (see dotsReadableEye) with data columns:
      %  1. timestamp
      %  2. gaze x
      %  3. gaze y
      %
      function data = loadRawData(filename, ecodes, helper)
         
         % Set up the return values
         data.tags = {'time', 'gaze_x', 'gaze_y'};
         data = [];

         % Need filename argument
         if nargin < 1 || isempty(filename) || ~exist(filename, 'file')
            return
         end
         
         % To scale eye data (also could smooth)
         if nargin < 3
            gainH = 1;
            gainV = 1;
         else
            gainH = helper.rawGainH;
            gainV = helper.rawGainV;
         end
         
         % Constants to parse data
         TTLcutoff = 2.0;
         TTLmaxPulseInterval = 0.2;
         
         % Load the data from the file and parse channels
         S = load(filename);
         channels = fieldnames(S);
            
         % Loop through the data
         for ii = 1:length(channels)
            
            % Make the time axis
            times = ((0:S.(channels{ii}).length-1).*S.(channels{ii}).interval)';
            
            % TTL
            if strcmp(S.(channels{ii}).title, 'TTL')%any(sum(S.(channels{ii}).values > TTLcutoff))
               
               % Make data matrix with columns:
               %  1. TTL trial onset times from spike2
               %  2. TTL pulse number per trial from spike 2
               
               % Time of each pulse
               TTLtimes = times([diff(S.(channels{ii}).values > TTLcutoff)==1; false]);
               
               % Time of first pulse
               TTLtrialTimes = [TTLtimes([true; diff(TTLtimes) > TTLmaxPulseInterval]); inf];
               
               % Data matrix
               data.TTL = nans(length(TTLtrialTimes)-1, 2);
               
               % Loop through and count the pulses per burst
               for tt = 1:length(TTLtrialTimes)-1
                  data.TTL(tt,:) = [TTLtrialTimes(tt), ...
                     sum(TTLtimes >= TTLtrialTimes(tt) & TTLtimes < TTLtrialTimes(tt+1))];
               end
               
            elseif strcmp(S.(channels{ii}).title, 'EOGH')
               
               % Horizontal eye data
               hEye = cat(2, times, S.(channels{ii}).values.*gainH);
               
            elseif strcmp(S.(channels{ii}).title, 'EOGV')
               
               % Vertical eye data
               vEye = cat(2, times, S.(channels{ii}).values.*gainV);
               
            elseif strcmp(S.(channels{ii}).title, 'MICRO')
               
               % Electrode channel
               data.spikes = cat(2, times, S.(channels{ii}).values);
            end
         end
         
         % analog is time, horizontal eye, vertical eye
         data.analog = cat(2, hEye, vEye(:,2));
         
         % Calibrate and synchronize
         if nargin > 1 && ~isempty(ecodes)
            
            % First need to get synchronization data
            %
            % Only for trials for which we fount TTLs
            ecodes.data = ecodes.data(1:min(size(ecodes.data,1), size(data.TTL,1)),:);
            
            % Get relevant ecodes
            getCol = @(x) ecodes.data(:, find(strcmp(x, ecodes.name),1));            
            trialStartTimes = getCol('trialStart');
            TTLStartTimes   = getCol('TTLstart');
            TTLNum          = getCol('TTLnum');
            
            % Collect sync data: 1) referenceTime, 2) offset
            syncData = nans(size(data.TTL,1), 2);
            for tt = 1:size(data.TTL,1)
               if data.TTL(tt,2) == TTLNum(tt)
                  syncData(tt,:) = [ trialStartTimes(tt),  ...
                     TTLStartTimes(tt) - data.TTL(tt,1)];
               else
                  disp('dotsReadableSpike2.loadRawData WARNING: TLL numbers do not match')
               end
            end

            % Calibrate
            %
            % Get indices of relevant data columns
            eti  = find(strcmp(tags, 'time'));
            exi  = find(strcmp(tags, 'gaze_x'));
            eyi  = find(strcmp(tags, 'gaze_y'));

            % Get the calibration data
            calibrationData = topsDataLog.getTaggedData('calibrate dotsReadableEyeEOG');
            
            % Put the calibration times in the spike2 timebase
            for cc = 1:numel(calibrationData)
               
               adiffs = abs(calibrationData(cc).item.timestamp - syncData(:,1));
               ind = find(adiffs==min(adiffs),1);
               calibrationData(cc).item.timestamp = ...
                  calibrationData(cc).item.timestamp - syncData(ind,2);
            end
            
            % Calibrate from the dataLog calibration data
            data.analog(:,[eti exi eyi]) = dotsReadableEye.calibrateGazeSets( ...
               data.analog(:,[eti exi eyi]), calibrationData);

            % Synchronize
            %
            data.analog = dotsReadableEye.parseRawData(data.analog, tags, syncData);
         end 
      end
   end
end

