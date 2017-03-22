
classdef Logic < handle
    % CP for FallingBallTaskRun
    
    properties
           
        % Hazard rate within trial
        H = 0.05;            
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
        
    end
end
