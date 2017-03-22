function pickSound(varargin)



% pick a new sound for this trial?
p = .8
newSound=binornd(1, p, 1)

if newSound==1
    %probability of getting a generic repeated sound
    genProb=.7
    genSound=binornd(1,genProb,1)

    if genSound==1
        rSet('dXsound', 4, 'rawSound', 'pause.wav')
        fp=0
        %rPlay({'dXsound', 4})
    else

        %setup array of possible image files

        sounds={'1 up.wav', 'Cannon Shot.wav', 'Fireball.wav', 'Mario Jump.wav', ...
            'Power Up.wav', 'Super Mario 2 - Die.wav', 'Super Mario 2 - Door.wav', 'Super Mario 2 - Jump.wav',...
            'Super Mario 3 - Power Up.wav', 'Super Mario 3 - Start Stage.wav', 'Super Mario 3 - Power Up', 'Super Marior 2 - Lose Chance.wav',...
            'Super Mario 2 - Throw.wav', 'Super Mario 2 - Game Over.wav', 'Mario Jump.wav', 'Super Marior 2 - Pick Up.wav'};
        % pick a specific sound to play this trial
        size(sounds,2)
        size({sounds},2)
        
        fp=ceil(rand(1).*size(sounds,2))
        rSet('dXsound', 4, 'rawSound', sounds{fp})
        snd=(rGet('dXsound',4,'rawSound'))
        maxAmp=max(snd)
        rSet('dXsound', 4, 'gain', 1./maxAmp)
    end

    rSet('dXtext', [10], 'string', fp);
end
   
rPlay('dXsound', 4);



