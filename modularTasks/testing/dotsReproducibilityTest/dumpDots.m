function dumpDots(taskName, sessionTimeStamp, rawDataPath)
% dump dotsInfo contained in task objects. This function loops through all 
% the children of the topsTreeNodeTopNode object and aggregates the data
% in dotsInfo into a single table. Then, the table is dumped as a CSV file
% with filename [sessionTimeStamp, '_dotsPositions.csv'], in the same
% folder where the raw data for the session (the topsDataLog) lives.
% ARGS:
%   taskName            e.g. 'oneCP'
%   sessionTimeStamp    e.g. '2019_09_30_11_35'
%   rawDataPath         e.g. '/Users/adrian/oneCP/raw/';

[topNode, FIRA] = topsTreeNodeTopNode.loadRawData(taskName, sessionTimeStamp);

% columns of following matrix represent the following variables
subjNumber=99;  % dummy number
dotsColNames = {...
    'xpos', ...
    'ypos', ...
    'isActive', ...
    'isCoherent', ...
    'frameIdx', ...
    'seqDumpTime', ...  % time at which whole sequence of frames was dumped; recall that this is done once per trial, right before exiting the state machine.
    'pilotID', ...
    'taskID'};

fullMatrix = zeros(0,length(dotsColNames));
end_block = 0;

for taskID=1:length(topNode.children)
    taskNode = topNode.children{taskID};
    numTrials=length(taskNode.dotsInfo.dotsPositions);
    if numTrials ~= length(taskNode.dotsInfo.dumpTime)
        error('dumpTime and dotsPositions have distinct length')
    end

    for trial = 1:numTrials
        dotsPositions = taskNode.dotsInfo.dotsPositions{trial};
        dumpTime = taskNode.dotsInfo.dumpTime(trial);
        numDotsFrames = size(dotsPositions,3);

        for frame = 1:numDotsFrames
            numDots = size(dotsPositions,2);

            start_block = end_block + 1;
            end_block = start_block + numDots - 1;

            fullMatrix(start_block:end_block,:) = [...
                squeeze(dotsPositions(:,:,frame)'),...
                repmat([frame,dumpTime,subjNumber,taskID],numDots,1)];
        end
   end
end

csvPath = [rawDataPath, sessionTimeStamp, '/'];
U=array2table(fullMatrix, 'VariableNames', dotsColNames);
writetable(U,[csvPath,sessionTimeStamp,'_dotsPositions.csv'],...
    'WriteRowNames',true)
disp('dots written')
