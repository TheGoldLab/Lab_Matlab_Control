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

# Eyetracker Libraries

These are tasks exclusively for use with the eyetracker hardware. The code is similarly organized as before with a couple modulations:

1. New input device (getNextEvent_clean, pause_trial)

* The psychophysics computer allows the use of a gamepad to be used for input subject response. I find the gamepad to be more intuitive and ergonomic so I have replaced the mglGetKeyEvent keyboard input with dotsReadableHIDGamepad game controller input. 

   The code to set up the gamepad is in the configure file in the section commented “Set up UI Reader”. The gamepad is used in the following functions:

* pause_trial is executed to pause the experiment before the display of the dots motion. It waits for a response from the gamepad (indicated by the press of button A) to allow the experiment to continue.

* getNextEvent_clean waits for the game controller input of left (indicated by pressing the left bumper) or right (indicated by the right bumper).

2. Eyetracker hardware - Trial Recording

* The eyetracker code is setup in the section commented “Eyelink Initialization”. There you will be able to configure the eyetracker to the participant. Once you are satisfied with the configuration press the output/record button to return the program to the experimental paradigm.

   There are 4 parts of the experiment where the eyetracker is called again to record a message. This is used to record time points during the experiment for post experiment analysis. The eyetracker returns one continuous time series edf file and we use this time point to parse the part of the time series we are interested in. The time point recordings of interest are indicated below:

   Eyelink('Message', 'STIMSTART');  
   This is recorded after the program is prepared to draw and will start drawing the stimulus  
   Eyelink('Message', ‘STIMSTOP’);  
   This is recorded as soon as the program ceases drawing the dots  
   Eyelink('Message', 'TRIALSTART');  
   This is recorded before the program prepares to draw  
   Eyelink('Message', 'TRIALEND');  
   
   This is recorded after the user has made their choice and the program has recorded the data and is ready to cease

   I placed these time point recordings here so that the time between STIMSTART and STIMSTOP will border the time the stimulus (dot motion) is shown. The time between TRIALSTART and TRIALSTOP will border most of the experiment so it should also include information on the user during and right after the decision.

   Disclaimer: I have not completing testing on these timepoints. It has not been verified these timepoints will capture the intended information. There are factors to watch out for such as length of machine implementation (e.g. changing isVisible to false will not have an immediate effect of turning off the stimulus as the program has to complete the current draw cycle before implementing changes in the next). There might be other hidden machine level processes that might add a variety of extra time to our time boundaries. Further testing should be done to verify the accuracy of these timepoints.

   Disclaimer / Warning: I developed most of the code using only one experimental block. If you were to change nBlocks (located in scriptRun.m) to be more than 1 I can spot one error you will encounter:

* configFinishTrial contains code to turn off the Eyetracker and record the current data to an EDF file. The logic of the function is set to execute if the trial count has reached the amount set in logic.trialsPerBlock (this is set by trialsPerBlock in scriptRun.m). This logic is currently agnostic of the amount of blocks you have set, thus it will stop the eyetracker after only one block has finished even if you have more set to run. This can be fixed by adjusting the logic of the if statement. 

* Other potential errors and parts of the code I didn’t understand are detailed by comments in the code. Search “TODO” to find them. 

3. Eyetracker Hardware - Focus of pupil on focal point

* To verify that the participant is focused on the task, we can detect if their gaze drifts away from the focal point (middle of the screen). 

   This code is implemented in record_stim and calls the function checkFixationHold which updates the value of list{'Eyelink'}{'FixVal'} to be 0 if fixation on the focal point is not held. 

* The function checkFixation is also added as it is called upon by checkFixationHold. 

* Be sure to include the MLEyelinkCalibrate.m file to call the functions needed to set up the eyetracker.

# TAFCDots_coh_drop_V3_eyetracker

The experimental paradigm of this is heavily updated from the similarly named non-Eyelink code. 

Experimental paradigm:

![Experimental paradigm](https://raw.githubusercontent.com/TheGoldLab/Lab-Matlab-Control/master/Tasks/Justin_TAFCDots/images/EP.png "Experiment")

This is a visualization of the trial paradigm. This is similar to the non-Eyelinker version of this experimental paradigm. Artificial changepoints are still set for low hazard trials. Details for all of these are set in scriptRun.m

A major change is there will be a signal (change of focal point to yellow) that probabilistically indicates the last changepoint has occurred. Probabilistically is set that 50% of the time the yellow signal occurs it accurately denotes a change point and the other 50% the signal is meaningless (random point chosen between the end of the linear drop (1.5 seconds) and the end of the experiment). 

To be clear, there will always be a yellow signal displayed, but 50% of the time they indicate the last change point has occurred, and the other half of the time they are meaningless.

# TAFCDots_coh_drop_V4

This is a furter extension of V3. We add a variable to scriptRun.m called static_dot_reset. If this is set to false the signal, which is a movement freeze of all the dots on screen (switched from the yellow color signal), occurs indicating that this was the last change of direction. 

If it is set to true, then the signal still occurs at the last change in direction, but there is a 50% chance that direction might not change. This means the participant could have ignored all direction up until the signal.

# TAFCDots_coh_drop_V4_Eyetracker

Same as V4 except this includes eyetracker support.

# TAFCDots_QUEST_Eyetracker

This is the same exact QUEST+ paradigm as the previous version except it is ready to run on the Eyetracker computer with gamepad controls. There is no eye tracking information collected as we are just getting the threshold.	
