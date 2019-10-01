% Demonstrate some features of the dotsPlayble class family.
%
% @ingroup dotsDemos
function demoPlayables()

% create an object to play a sinusoidal tone
tony = dotsPlayableTone();
tony.frequency = 440;
tony.duration = 1;
tony.intensity = .25;

% play the tone
%   wait until the tone is done because playing happens "in the background"
tony.prepareToPlay();
tony.play();
pause(tony.duration);

%The PlayableNote function smoothes the sound so it doesn't abruptly end.
player = dotsPlayableNote();
player.frequency = 1000;
player.duration = 3;
player.intensity = .25;
player.prepareToPlay();
player.play();
pause(player.duration);

% alter the tone parameters and play it again
tony.frequency = 880;
tony.duration = 2;
tony.prepareToPlay();
tony.mayPlayNow();
pause(tony.duration);

% create an object to play a sound from a file
%   the "Coin.wav" is included along with Snow Dots
filey = dotsPlayableFile();
filey.fileName = 'Coin.wav';
filey.intensity = .1;

% play from the sound file
filey.prepareToPlay();
filey.mayPlayNow();
pause(filey.duration);

% alter the sound file intensity and play it again
filey.intensity = 1;
filey.prepareToPlay();
filey.mayPlayNow();
pause(filey.duration);

% try to play two sounds at once
%   this may fail with a bug in Matlab's audioplayer class
tony.mayPlayNow();
pause(tony.duration/2);
filey.mayPlayNow();
pause(filey.duration);
% try to play two sounds at once
%   this may fail with a bug in Matlab's audioplayer class
tony.mayPlayNow();
pause(tony.duration/2);
filey.mayPlayNow();
pause(filey.duration);
