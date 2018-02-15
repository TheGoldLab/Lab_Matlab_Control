function [idxInterpolation, pupilNew] = CubicSpline(windowToInterpolate, pupil,interpolationMargin)

%%
    if windowToInterpolate(end) == length (pupil) % If the last index is the end of the pupil array 
        pupil(windowToInterpolate(end)) =  pupil(windowToInterpolate(1) - 1);
        totalWindow     = [(windowToInterpolate(1) - (interpolationMargin-1)) : windowToInterpolate(1)-1, windowToInterpolate(end)]; 
        values          = pupil(totalWindow);
        idxInterpolation = windowToInterpolate(1)-interpolationMargin: windowToInterpolate(end);
    else
        totalWindow  = [(windowToInterpolate(1) - interpolationMargin ) : windowToInterpolate(1)-1, windowToInterpolate(end)+1: windowToInterpolate(end)+ interpolationMargin]; 
        values       = pupil(totalWindow);
        idxInterpolation = windowToInterpolate(1)-interpolationMargin: windowToInterpolate(end) + interpolationMargin;
    
    end

%----------Interpolation---------------------------------------------------

            x        = 1:length(totalWindow);
            xx       = linspace(1,length(totalWindow),length(windowToInterpolate)+length(totalWindow));%consider the size of the missing value + the integers before and after.
            pupilNew = spline (x, values, xx);
            

end