classdef Logic < handle
    % CP for FallingBallTaskRun
    
    properties
           
        % Hazard rate within trial
        H = [0.05 0.1 0.2 0.3 0.4 0.5 0.6 0.7 0.8 0.9 1] ;            
        % the number of trials to run total
        nTrials = 5;        
        %Sigma of Red Ball
        Sigma0  = 2;
        %Ratio
        R = 0.5;
        %Mean of Red Ball
        RedMean = 0;
        %Number of Observation Trials
        observation = 0;
        %Arrow position
        arrowposition = 1;        
        
    end
end
