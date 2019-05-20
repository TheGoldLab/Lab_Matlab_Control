function [ Scores ] = ScorerMattRaw( data )
%Gets Scores for a subject, must be done on parsed
delay=data.durationDelay;
type=data.sampleType;

        if type==1
    Scores=min(10,ceil(5+5*nanmean([data([data.correct]>.1).correct])));
        else
            Lowerbenchmark=nanmean(abs(diff([data.targetAngle])));
            Targets=[data.targetAngle];
            Means=[data.targGenDistMean];
            Means=[Means(1,1),Means(1:end-1)];
            Upperbenchmark=nanmean(abs(degAngDiff(Targets,Means)));
            
            PredictionError=nanmean(abs(degAngDiff([data.guessAngle],[data.NextAngle])));
            disp('mean pred err=');
            disp(PredictionError)
            disp('upperbenchmark=');
            disp(Upperbenchmark)
            disp('lowerbenchmark=');
            disp(Lowerbenchmark)
            if PredictionError>Lowerbenchmark
                Payout=5;
            elseif PredictionError> 2/3*Lowerbenchmark+1/3*Upperbenchmark
                Payout=8;
            elseif PredictionError> 1/2*(Lowerbenchmark+Upperbenchmark)
                Payout=9;
            else
                Payout=10;
            end
            
           Scores=Payout;
       
        end
       
end

