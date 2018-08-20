classdef PredInfAV < handle
    % Template for predictive inference task audio-visual behaviors.
    
    properties
        % a PredInfLogic object to work with
        logic;
        
        % how long to let the subject sit idle
        tIdle = 30;
        
        % how long to indicate that its time to predict
        tPredict = 0;
        
        % how long to let the subject update predictions
        tUpdate = 30;
        
        % how long to indicate subject commitment
        tCommit = 1;
        
        % how long to indicate the trial outcome
        tOutcome = 1;
        
        % how long to indicate the trial "delta" error
        tDelta = 1;
        
        % how long to indicate trial success
        tSuccess = 1;
        
        % how long to indicate trial failure
        tFailure = 1;
        
        % width of the task area in degrees visual angle
        width = 30;
        
        % height of the task area in degrees visual angle
        height = 20;
        
        % a string instructing the subject to wait, please
        pleaseWaitString = 'Please wait.';
        
        % a string instructing the subject to press a button
        pleasePressString = 'Press when ready.';

        % font size for all texts
        fontSize = 48;
    end
    
    methods
        % Set up audio-visual resources as needed.
        function initialize(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Clean up audio-visual resources as needed.
        function terminate(self)
            s = dbstack();
            disp(s(1).name)
        end

        % Return concurrent objects, like ensembles, if any.
        function concurrents = getConcurrents(self)
            concurrents = [];
        end
        
        % Give the previous or first task instruction.
        function doPreviousInstruction(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Give the next or last task instruction.
        function doNextInstruction(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Indicate that its time to predict.
        function doPredict(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Let the prediction reflect new subject input.
        function updatePredict(self)
        end
        
        % Indicate that the prediction is now commited.
        function doCommit(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Indicate the new trial outcome.
        function doOutcome(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Indicate the prediction "delta" error.
        function doDelta(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Indicate success of the trial.
        function doSuccess(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Indicate failure of the trial.
        function doFailure(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Describe feedback about the subject input.
        function doFeedback(self)
            s = dbstack();
            disp(s(1).name)
        end
        
        % Give a message to the subject.
        function doMessage(self, message)
            s = dbstack();
            disp(s(1).name)
            if nargin > 1
                disp(message);
            end
        end
    end
end