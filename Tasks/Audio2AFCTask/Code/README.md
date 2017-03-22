# Audio 2 Alternative Forced Choice Task (With Metahazard Rate)

**FUNCTION:** This task plays noises from the left or right side. On every trial, a weighted dice is rolled to determine whether the sound comes from the left or right. The weights of the dice switch according to a fixed hazard rate.

Additional twists:
* There is a METAhazard rate, which switches between the two different fixed hazard rates. These hazard rates are associated with their own pair of differently weighted dice.

***

**HOW TO USE:**

General form is: [task, list] = Audio2AFC(trials). The ‘task’ is the experiment that is actually run. The ‘list’ is what stores all the data.

If we wanted to run 100 trials, we enter:

>> [task, list] = Audio2AFC(100)

If you want to change the metahazard rate, you can open Audio2AFC.m and change the ‘metahazard’ variable.

To change the two different hazards rates, go to the ‘hazards’ matrix and change the values. The hazards are stored as a 2x1 vector.

To change the weights of dice roll, change ‘Adists’ or ‘Bdists’. The top number in ‘Adists’ or ‘Bdists’ represents the rate of switching from left-to-right, and the bottom number represents the rate of right-to-left. 

The ‘Adists’ are associated with the first value in the ‘hazards’ vector. The ‘Bdists’ are associated with the second value in the ‘hazards’ vector.

After all the parameters are set, we can run the task. First open the snow dots screen, then run, then close the screen.

>> dotsTheScreen.openWindow

>> task.run

>> dotsTheScreen.closeWindow


***

**DEPENDENCIES:**
* Snowdots
* Psychtoolbox
* The custom file dotsPlayableNote.m, which depends on Snowdots
* MGL Library
* Tobii SDK. Also a Tobii Eyetracker (T60XL, T120, or any of the SDK 3.0 compatible devices)

***

**OUTPUTS**:
*All outputs are stored in the ‘list’ variable.*

* Reaction Times
* Timestamps for all user input
* Gaze data from both eyes: X,Y-Coordinates, Pupil Diameter, and Tobii Validity Code
* Stimulus play times
