
# TAFCDots-Original

Original Code for Dots experiment. The code for every task I created is based off of this version. 

An example data output is included in the TAFCDotsData folder.

Please see https://github.com/TheGoldLab/Lab-Matlab-Control/wiki for detailed information about each component of the program.

# TAFCDots-Original_Justin 
1. Addition of scriptRun.m
scriptRun.m as an abstraction to Glaze’s original code to allow for faster adjustment of experimental design. All values set are saved to scriptRunValues to be globally accessible by the program. 

Adjust-1: The program relies on the library of Lab-Matlab-Control and mgl. Change the code at this location to allow the program find the location of the respective libraries on your computer. 


2. ConfigureTAFCDotsDur.m

Here we can adjust the graphical properties of the moving dots and the experimental paradigm. 

Adjust-1: This line will decide what screen to run the program on. 0 will run a small window while 1 will run a full screen version. Both will run in whichever screen MATLAB is hosted in. Look at this link for more information concerning the numbers and their properties: http://gru.stanford.edu/doku.php/mgl/functionReferenceScreen

getNextEvent_Clean: This function replaced the user input used in the original Glaze code as it had frequent problems with correctly registering user input. The original mglGetKeyEvent is reinstalled to handle all user input and it remove the problems with the original Glaze code. 
