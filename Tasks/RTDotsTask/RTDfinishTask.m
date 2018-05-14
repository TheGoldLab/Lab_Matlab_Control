function RTDfinishTask()
% function RTDfinishTask()
%
% RTD = Response-Time Dots
%
% Clean up at the end of running a task (topsTreeNode child).
%
% Inputs:
%  datatub            ... A topsGroupedList object containing experimental 
%                          parameters as well as data recorded during the 
%                          experiment.
% 
% 5/11/18 created by jig      

%% -- Save and flush logged data
topsDataLog.writeDataFile();
topsDataLog.flushAllData(); % Flush again to keep memory demands low
