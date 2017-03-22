% show a line that grows and shrinks with f and j keys

    rInit('local');
        rAdd('dXline', 1, 'x1', -15, 'y1', 0 , 'x2', -15, 'y2', 0, ...
    'visible', true, 'penWidth', 5, 'color', [255 255 0]);

%%%sets up parameters for first random line + number
            f= normrnd(100, 40) 
            g=round(f) 
            h=.1*g-15
%%%Top and bottom white lines
top = rAdd('dXline', 1, 'x1', -15, 'y1', 2 , 'x2', 15, 'y2', 2, ...
    'visible', true, 'penWidth', 3, 'color', [255 255 255]);
botton = rAdd('dXline', 1, 'x1', -15, 'y1', -1 , 'x2', 15, 'y2', -1, ...
    'visible', true, 'penWidth', 3, 'color', [255 255 255]);

%%random line and random number (invisible until h pushed)
random = rAdd('dXline', 1, 'x1', -15, 'y1', 1 , 'x2', h, 'y2', 1, ...
          'visible', false, 'penWidth', 5, 'color', [0 0 255]);
rand = rAdd('dXtext', 1, 'size', 60, 'string', g, 'x', 0, 'y', 5 , ...
    'visible', false, 'color', [0 0 200]);
      
      
%%sets subject guess at zero and makes line 0 length    
v=0

guess = rAdd('dXtext', 1, 'size', 60, 'string', v, 'x', 0, 'y', -3 , ...
    'visible', true, 'color', [255 255 0]);

%%adds line and text describing the difference between guess and rand

k=abs(v-g)

diffText = rAdd('dXtext', 1, 'size', 40, 'string', k, 'x', -6, 'y', 13 , ...
    'visible', false, 'color', [0 255 255]);



diff = rAdd('dXline', 1, 'x1', g, 'y1', .5 , 'x2', (.1*v)-15, 'y2', .5, ...
          'visible', false, 'penWidth', 5, 'color', [0 255 255]);



      
      %% add score and total score text and scores
      

      
totScore = rAdd('dXtext', 1, 'size', 40, 'string', 'total score', 'x', 4, 'y', 13 , ...
    'visible', true, 'color', [255 0 0]);   
 

z=0
totDiff = rAdd('dXtext', 1, 'size', 40, 'string', z, 'x', 12, 'y', 13 , ...
    'visible', true, 'color', [255 0 0]);
    
      
rGraphicsDraw; 










% how fast does the bar change?
step = .1;

key = nan;
rGraphicsDraw;
while ~strncmp(key, 'q', 1)
    [press, when, keyCode] = PsychHID('KbCheck');
    if press
        key = dXkbName(keyCode);
        if strncmp(key, 'f', 1)
            rSet('dXline', 1, 'x2', rGet('dXline', 1, 'x2')-step);
            v=v-1;
            rSet('dXtext', guess, 'size', 60, 'string', v, 'x', 0, 'y', -3 , ...
                'visible', true, 'color', [255 255 0]);
            rGraphicsDraw;

        elseif strncmp(key, 'j', 1)
            rSet('dXline', 1, 'x2', rGet('dXline', 1, 'x2')+step);
            v=v+1;
            rSet('dXtext',guess, 'size', 60, 'string', v, 'x', 0, 'y', -3 , ...
                'visible', true, 'color', [255 255 0]);
            rGraphicsDraw;

        elseif strncmp(key, 'h',1)
            f= normrnd(100, 10) ;
            g=round(f) ;
            h=.1*g-15;
            rSet('dXline', random, 'visible', true, 'x2',h);
            rSet('dXtext', rand, 'visible', true, 'string', g);
            rGraphicsDraw;
            %%%show the difference...
            WaitSecs(.01);
            k=abs(v-g);
            rSet('dXline', diff, 'visible', true, 'x2', (.1*v)-15, 'x1', h);
            rSet('dXtext', diffText, 'visible', true, 'string', k);
            z=z+k;
            rSet('dXtext', totDiff, 'string', z);
            
            
            
            rGraphicsDraw;
            
        end
    end
end
rDone;

   
            
  
            













