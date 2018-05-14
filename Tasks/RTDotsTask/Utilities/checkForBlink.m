function isBlinking = checkForBlink(eyelinkSamples,invalid)
% blink = checkForBlink(eyelinkSamples)
% 
% This function takes in a series of Eyelink data samples and checks
% whether or not the subject has blinked. This is done by checking whether
% any of the samples has invalid or empty values. This indicates that the
% Eyelink has not picked up the subject's eyes.
%
% Inputs:
%   eyelinkSamples  -  An array of eyelink data samples.
%   invalid         -  Value that eyelink sets when eye cannot be recorded.
%
% Outputs:
%   isBlinking  -  A boolean specifying whether the subject is blinking.
%
% 9/20/17    xd  wrote it

%% Initialize blink to false
isBlinking = false;

%% Check that all samples exist
%
% We want to make sure that the input does not contain empty cells. If this
% is the case, just return with blink being set to true.
if any(isempty(eyelinkSamples))
    isBlinking = true;
    return;
end

%% Check for specific params
%
% Knowing that we have real values for each data sample, check whether the
% reported eye positions correspond to conditions that would indicate that
% there is a blink.
x = [eyelinkSamples.gx];
if any(isempty(x)) || any(x == invalid)
    isBlinking = true;
end

end

