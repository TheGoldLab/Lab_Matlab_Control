# Audio Reaction Time Task

**FUNCTION:** This is an audio reaction time task. Sounds will randomly play from the left or right sides on every trial, and the participant must correctly choose where the sound came from. Probability of playing from each side is dictated by a Markov Chain: there is one Hazard Rate (H1) that dictates probability of switching from the left side to the right side on the next trial, and another Hazard Rate (H2) that dictates switching from right side to left side on the next trial.

Additional twists:
* You can turn on distraction sounds, which will play random frequencies from 0-1000Hz during the task to distract.
* The amount of effort required from a user to choose which side a sound came from can be modulated. 0 Effort is a passive task. 1 Effort requires a single button press. 2 Effort requires a specific pattern of presses (think a Mortal Kombat combo).

***

**HOW TO USE:**

General form is: [task, list] = AudRTTaskT(effort, distractor_on). The ‘task’ is the experiment that is actually run. The ‘list’ is what stores all the data.

Effort = 0 is a passive task, Effort = 1 needs a single button press to report a side, Effort = 2 requires a combo to choose a side.

distractor_on = 0 means no distractor. distractor_on = 1 turns on the distractor.

To create a task that requires a combo press and has a distractor:

>> [task, list] = AudRTTaskT(2, 1)

Now we can run the task. First open the snow dots screen, then run, then close the screen.

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
*All these outputs are stored in the ‘list’ structure.*

* Reaction Times
* Timestamps for all user input
* Gaze data from both eyes: X,Y-Coordinates, Pupil Diameter, and Tobii Validity Code
* Stimulus play times
