
# TAFCDots-Original

Original Code for Dots experiment. The code for every task I created is based off of this version. 

An example data output is included in the TAFCDotsData folder.

Please see https://github.com/TheGoldLab/Lab-Matlab-Control/wiki for detailed information about each component of the program.

# TAFCDots-Original_Justin 
## 1. Addition of scriptRun.m

scriptRun.m as an abstraction to Glaze’s original code to allow for faster adjustment of experimental design. All values set are saved to scriptRunValues to be globally accessible by the program. 

Adjust-1: The program relies on the library of Lab-Matlab-Control and mgl. Change the code at this location to add these libraries to your path


## 2. ConfigureTAFCDotsDur.m

Here we can adjust the graphical properties of the moving dots and the experimental paradigm. 

Adjust-1: This line will decide what screen to run the program on. 0 will run a small window while 1 will run a full screen version. Both will run in whichever screen MATLAB is hosted in. Look at this link for more information concerning the numbers and their properties: http://gru.stanford.edu/doku.php/mgl/functionReferenceScreen

getNextEvent_Clean: This function replaced the user input used in the original Glaze code as it had frequent problems with correctly registering user input. The original mglGetKeyEvent is reinstalled to handle all user input and it remove the problems with the original Glaze code. 

# TAFCDots_coh_drop

The experimental task builds off of TAFCDots-Original_Justin. The gist of the task is that we wanted to show dot motion at a high coherence during the beginning of the trial, then linearly decrease the coherence to the specified low coherence. To implement this there was changes added to scriptRun.m, configureTAFCDotsDur.m, and dotsDrawableDynamicDotKinetogram.m which are detailed below. 

Duration is now decided by three factors: length_of_high, length_of_drop, variable duration
Length_of_high, and length_of_drop are constant and are defined in scriptRun.m
Duration varies (to prevent participants from predicting how the trial ends) and the variation is defined through the following factors:

* minT = low coherence trial duration minimum
* maxT = high coherence trial duration maximum
* H3 = seed for exprnd() to vary trial duration between minT and maxT
* Pseudocode:
..* Duration of low coherence is minT + exprnd(H3), but is bounded above by maxT

This file also adds an artificial changepoint. Before, changepoint occurrence relied on probability which is affected by the set hazard rate. We can add a mandatory changepoint near the end. This helps for low hazard trials where in a majority, the observer will never see a changepoint meaning that the trial is useless for data analysis. 

We add an artificial changepoint near the end of the trial. This allows us to probe the crossover effect region more.

First, enable the artificial changepoint through the variable TAC_on in scriptRun. 
* Recommended for low hazard trials. Can leave on for high hazard trials, but it has little effect on the data. 

Next you can define the range and dynamics of the chosen time point for the crossover.
* cp_minT defines how far from the end of the trial can the artificial changepoint be added
* cp_maxT defines how early from the end of the trial can the artificial changepoint be added
* cp_H3 is the value fed to exprnd() to choose the exact time for the changepoint between cp_minT and cp_maxT

# TAFCDots_coh_drop_V2 

Minor additions to the first version:

* pause_trial function is added which mandates the next trial starts by pressing the space bar. Allows the subject to take a break and proceed at their own pace.

* 25% of all trials will remain at high coherence while the other 75% have the linear drop to low coherence. This is hardcoded and can be changed in the configure folder (look for “25 chance of having a high coherence trial” in the comments)

* The ability to turn on and off the artificial changepoints is added to scriptRun.m (look for the variable “TAC_on”). Before you had to manually turn them off in the configure folder. 

* scriptRun.m is cleared of unnecessary variables (e.g. QUEST variables did not have any use before).

# TAFCDots_QUEST 

Run this to get the dot motion threshold of each participant with QUEST+

The setup is the same as the others (addition of scriptRun.m, getNextEvent_Clean in configure).

Current experimental paradigm is the same as the Glaze 2015 paper (500 millisecond trials with 0 hazard rate).

Be sure the QUEST+ library is included. Set the add path function to find the QUEST+ library in scriptRun.m. I have already included the QUEST+ library in this repository (Downloaded October 1st, 2017).
(https://github.com/brainardlab/mQUESTPlus, http://jov.arvojournals.org/article.aspx?articleid=2611972)

