   
    %Standard
    distractplayer = dotsPlayableNote();
    distractplayer.duration = 1;
    distractplayer.noise = 0;
    distractplayer.frequency = 1000;
    distractplayer.intensity = 0.8;
    distractplayer.ampenv = tukeywin(distractplayer.sampleFrequency*distractplayer.duration)';
    
    distractplayer.prepareToPlay();
    distractplayer.mayPlayNow(); 
    pause(distractplayer.duration);
    
    % Oddball
    distractplayer = dotsPlayableNote();
    distractplayer.duration = 1;
    distractplayer.noise = 0;
    distractplayer.frequency = 2000;
    distractplayer.intensity = 0.8;
    distractplayer.ampenv = tukeywin(distractplayer.sampleFrequency*distractplayer.duration)';
      
    distractplayer.prepareToPlay();
    distractplayer.mayPlayNow(); 
    pause(distractplayer.duration);
    
