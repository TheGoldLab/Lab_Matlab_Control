function d_ = newMeanNewSubBlockSize(d_)


    % pick new mean for the current distribution
    bi = mod(d_.blockIndex-1, length(d_.metaD))+1;
    dis = d_.distributions(bi);

    
 
    
    %% this is for changing hazard rate in HH version
    global FIRA
    if ~isempty(FIRA) 
        trialnum=FIRA.ecodes.data(end-1, find(strcmp(FIRA.ecodes.name, 'trial_num')))
        total=d_.totTrials

        if total > 300

            if trialnum> total/3 & trialnum < total/1.5
                medSS=4
            elseif trialnum>= total/1.5
                medSS=32
            elseif trialnum<= total/3
                medSS=32
            end
            d_.metaD.args={medSS}
        end
    end


    %% this is where you would add something to put special cases in... for
    %% example pick a random binomial with a certain probability... if it
    %% comes up heads pick mean and standard deviation as below, if tails
    %% to a very specific case.  should be simple once the cases are
    %% identified.  might also need a way to specify whether to do this.
    
    
    arg = dis.args;
    sig = arg{2};         
    dist=60;
    mu = round(dist+((300-2*dist)*rand));
    arg{1} = mu;
    
    if ~isfinite(sig) || sig~=round(sig)
        sig =  rand.*40;
        arg{2} = sig;
    end



    dis.args = arg;
    d_.distributions(bi) = dis;

    % pick new subBlock size
    %sbs = round(rand*40) + 5;
    m = d_.metaD(bi);
    sbs = 5 + round(exprnd(m.args{1}));
    d_.subBlockSize = sbs;

    disp(sprintf('mu = %d,\tsig = %d,\tsubBlock = %d', mu, sig, sbs));

