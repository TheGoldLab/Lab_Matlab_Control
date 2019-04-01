# snow-dots
Custom utilities written in an object-oriented framework for controlling the components of a psychophyiscs experiment (e.g., graphics, sounds, etc).

# Configuration
1. Set-up a machine-specific configuration file. In Matlab, type:

   -> dotsTheMachineConfiguration.writeUserSettingsFile()
   
You can give it an optional filename as an argument, or it will make one by default based on your machine name. Make sure this file is saved somewhere on your path, and preferably not in your local copy of this gitHub repository. It is an editable text file. Two fields that you should be careful to check/update are the monitor width and viewing distance, both in cm. These values are used to render the graphics in units of degrees visual angle relative to the observer.

2. Make sure the monitor is gamma-corrected, using dotsTheScreen.makeGammaTable(). See that function for more details, including how to set up the hardware needed for these measurements.

3. Test other graphics benchmarks. See snow-dots/utilities/benchmarking


Be sure to check out the Wiki if you are just getting started!
