#! python3
import pyautogui, sys, time
#print('Press Ctrl-C to quit.')
while True:
    x, y = pyautogui.position()
    positionStr = ',' + str(x).rjust(4) + ',' + str(y).rjust(4)
    print( time.time(), positionStr, '\n', flush=True)
    time.sleep(0.05)