function [pupilFiltered ] = CleanBlinks(origPupil,frequency,interpolationMargin,temporalMargin,filterOrder,sub,OnsAndOffs)
    
% Main variables    
    pupil          =  medfilt1(double(origPupil),filterOrder);
%     velocity       =  diff(pupil);%pupil
    cleanPupil     =  pupil; % by default this variable is stored with all the pupil data
    
% Parameters to modify if needed
    %thresholdLow      = -(mean(velocity)+ std(velocity));
 %   thresholdHigh     = 1;
    origPupilNoBlinks = origPupil;
    origPupilNoBlinks(origPupil==0) = NaN;
    stdDiameter       = nanstd(origPupilNoBlinks);
    
    if nargin < 3
        temporalMargin = 70;
        interpolationMargin= 50;
        filterOrder = 200;
    elseif nargin < 4
        temporalMargin = 70;
        filterOrder = 200;
    elseif nargin < 5
        filterOrder = 200;   
    end

% Vectors to increment    
    i=1;
    blinksOnDiameter  = [];
    blinksOnTime      = [];  % Theses variables are used to plot the figure but are not required for the code to work
    blinksOffDiameter = [];
    blinksOffTime     = [];
      
    

for blinkEvs=1:length(OnsAndOffs)
    blinkOnset     = max(1,OnsAndOffs(1,blinkEvs)-temporalMargin);
    BlinkOffset=  min(OnsAndOffs(2,blinkEvs)+temporalMargin,OnsAndOffs(2,end));
                
            windowToInterpolate = blinkOnset+1:BlinkOffset+1; %+1 because diff shift the cells
       
            [idxInterpolation, pupilNew] = CubicSpline(windowToInterpolate, pupil,interpolationMargin);
            cleanPupil (idxInterpolation)= pupilNew;
            i=idxInterpolation(end)+1;
               
            % Variables to plot the figures              
            blinksOffDiameter = [blinksOffDiameter, pupil(BlinkOffset)];
            blinksOffTime     = [blinksOffTime, BlinkOffset];
            blinksOnDiameter = [blinksOnDiameter, pupil(OnsAndOffs(1,blinkEvs)-temporalMargin)];
            blinksOnTime     = [blinksOnTime, blinkOnset];
            
end
        
%         end
%         i=i+1;
%     end
 disp('here');
      %% Use a butterworth filter on the data 
      % (This is what get the signal smoother)
        mat = cleanPupil;
        mat = double(mat);
        order  = 2; % filter order: affects the height of the occilation
        cutoff = 4; % cut off frequency: affects the irregularities of the curve = higher is the cut-off frequency, closer you get to the original fluctuations of the curve.
        [a,b] = butter(order,cutoff/(0.5*frequency),'low');
        pupilFiltered = filtfilt(double(a),double(b),mat);
        
    %% Print figure of the data
    x = (1/frequency)/60:(1/frequency)/60:(length(origPupil)/frequency)/60;
    
%     figure();hold on;
%     ylabel('\bf{Pupil diameter}','FontSize', 18);
% %     xlabel('\bf{Time(min)}','FontSize', 18);
%          org            = plot(x,origPupil,'-b');hold on; 
%          filtPupil      = plot(x,pupil,'-g'); 
%         noBlinksFilt   = plot(x,cleanPupil,'-k'); 
%         butterFilt     = plot(x,pupilFiltered,'-m');
%         startBlinks    = plot(blinksOnTime/frequency/60, blinksOnDiameter, 'or','lineWidth',3);
%         endBlinks      = plot(blinksOffTime/frequency/60, blinksOffDiameter, 'og','lineWidth',3);
%         legend([org, filtPupil,noBlinksFilt,butterFilt, startBlinks,endBlinks]...
%             ,'Raw','Filtered','No blinks and filtered','Butterworth','Blink onset','Blink offset');
%         hold off;
%  
   
%   %% Save figure
%       saveName = (['Subject', int2str(sub)]);
%       saveas(gcf,(strcat('C:\Users\Hannah\Documents\POSTDOC\Matlab_postdoc\ExpePsychPhysic\',saveName)), 'fig');
%       close 
end